<template>
  <div class="py-2 caption">
    <v-card flat outlined class="pa-2">
      <h4>WebAuthn</h4>
      <div v-if="!supported">
        <p>This browser does not support WebAuthn.</p>
      </div>
      <div v-else>
        <div v-if="status == 'ACTIVE'">
            <p>You have enrolled WebAuthn.</p>
            <v-form>
                <v-btn 
                    small 
                    outlined 
                    @click="reset"
                > Remove</v-btn>
            </v-form>
        </div>
        <div v-else>
            <div v-if="status == 'NOT_SETUP'">
            <p>Available for enrollment</p>
            <v-form>
                <v-btn 
                    small 
                    outlined 
                    @click="enroll" 
                    :disabled="progress"
                >Setup</v-btn>
            </v-form>
            </div>
        </div>
      </div>
      <v-overlay :value="overlay">
        <v-btn>
          {{ overlayMessage }}
        </v-btn>
      </v-overlay>
    </v-card>
  </div>
</template>

<script>
import axios from "axios";

export default {
  name: "webauthn",
  data() {
    return {
      status: undefined,
      factor: undefined,

      overlay: false,
      overlayMessage: undefined,

      supported: false,
      enrollment: undefined,
      progress: false,
    };
  },
  props: {
    factorCatalog: Object,
  },
  mounted() {
    // Check if browser supports Credential Management
    this.supported = "credentials" in navigator;

    if (this.supported) {
      this.updateCatalog();
    }
  },
  watch: {
    factorCatalog: {
      deep: true,
      handler() {
        if (this.factorCatalog.catalog) {
          this.updateCatalog();
        }
        this.factor = this.factorCatalog.factor;
      },
    },
  },
  methods: {
    binToStr(bin) {
      return btoa(
        new Uint8Array(bin).reduce(
          (s, byte) => s + String.fromCharCode(byte),
          ""
        )
      );
    },
    strToBin(str) {
      return Uint8Array.from(atob(this.base64UrlSafeToBase64(str)), (c) =>
        c.charCodeAt(0)
      );
    },
    base64UrlSafeToBase64(str) {
      return str
        .replace(new RegExp("_", "g"), "/")
        .replace(new RegExp("-", "g"), "+");
    },
    updateCatalog() {
      if (this.factorCatalog && this.factorCatalog.catalog) {
        this.enrollment = this.factorCatalog.catalog.enrollment;
        this.status = this.factorCatalog.catalog.status;
        this.vendorName = this.factorCatalog.catalog.vendorName;
      }
    },
    async enroll() {
      const accessToken = await this.$auth.getAccessToken();
      this.overlayMessage = undefined;
      try {
        const res = await axios.post(
          this.$config.api + "/api/v1/users/" + this.$root.$children[0].userinfo.sub + "/factors",
          {
            factorType: this.factorCatalog.catalog.factorType,
            provider: this.factorCatalog.catalog.provider,
          },
          {
            headers: { Authorization: "Bearer " + accessToken },
          }
        );
        console.log("Got response", JSON.stringify(res.data));
        if (res.status == 200) {
          window.setTimeout(() => {
            this.overlay = false;
          }, 600);
          this.status = res.data.status;
          this.factor = res.data;

          // Must convert activation object's challenge and user id from string to binary.
          // See https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions
          let activation = res.data._embedded.activation;
          activation.challenge = this.strToBin(activation.challenge);
          activation.user.id = this.strToBin(activation.user.id);

          // Create Credentials in CredMan
          const newCredential = await navigator.credentials.create({
            publicKey: activation,
          });

          // Get attestation and clientData and convert from binary to string
          let attestation = this.binToStr(newCredential.response.attestationObject);
          console.log("attestation", JSON.stringify(attestation));

          let clientData = this.binToStr(newCredential.response.clientDataJSON);
          console.log("clientData", JSON.stringify(clientData));

          // Activate WebAuthn factor by verifying the attestation and client Data
          const res2 = await axios.post(
            this.$config.api + "/api/v1/users/" + this.$root.$children[0].userinfo.sub + "/factors/" + this.factor.id + "/lifecycle/activate",
            {
              attestation,
              clientData,
            },
            {
              headers: { Authorization: "Bearer " + accessToken },
            }
          );
          console.log("Activation Response", JSON.stringify(res2.data));

          if (res2.status == 200) {
            this.status = res2.data.status;
          }
        }
      } catch (err) {
        console.log("err", err);
        console.log("Error", JSON.stringify(err.response.data));
        this.overlay = true;
        try {
          this.overlayMessage = err.response.data.errorCauses[0].errorSummary;
        } catch (e) {
          //lazily handle unexpected responses
          this.overlayMessage = "invalid request";
        }
        window.setTimeout(() => {
          this.overlay = false;
        }, 2500);
      }
      this.emitUpdate();
    },
    async reset() {
        const accessToken = await this.$auth.getAccessToken();
        this.overlayMessage = undefined;
        try {
            await axios.delete(
                this.$config.api + "/api/v1/users/" + this.$root.$children[0].userinfo.sub + "/factors/" + this.factor.id,
                {
                    headers: { Authorization: "Bearer " + accessToken },
                }
            );
        } catch (err) {
            this.overlay = true;
            try {
                this.overlayMessage = err.response.data.errorCauses[0].errorSummary;
            } catch (e) {
                //lazily handle unexpected responses
                this.overlayMessage = "invalid request";
            }
            window.setTimeout(() => {
                this.overlay = false;
            }, 2500);
        }
        this.emitUpdate();
    },
    emitUpdate() {
      this.$emit("factor-updated", {
        catalog: this.factorCatalog.catalog,
        factor: this.factor,
      });
    },
  },
};
</script>