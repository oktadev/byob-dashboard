<template>
  <div class="py-2 caption">
    <v-card flat outlined class="pa-2">
      <h4>{{ authenticatorName }}</h4>
      <div v-if="status == 'ACTIVE'">
        <p class="success--text">
          You have an enrolled {{ authenticatorName }}.
        </p>
        <v-btn small outlined @click="reset" :disabled="progress">Remove</v-btn>
      </div>
      <div v-else>
        <div v-if="status == 'NOT_SETUP'">
          <p>Available for enrollment</p>
          <v-btn small outlined @click="enroll" :disabled="progress"
            >Setup</v-btn
          >
          <v-dialog v-model="displayQRCode" width="300" persistent>
            <v-card class="pt-4 px-0 pb-1">
              <div class="px-4">
                <div class="text-body-2">
                  Please scan the QR code below with your
                  {{ authenticatorName }} app.
                </div>
                <div>
                  <img :src="enrollQR" />
                </div>
                <v-btn
                  v-if="push"
                  small
                  outlined
                  @click="
                    displayQRCode = false;
                    progress = false;
                  "
                  >Cancel</v-btn
                >
                <v-form ref="activationform" v-else>
                  <div class="text-subtitle-2">THEN:</div>
                  <v-card
                    outlined
                    flat
                    class="pa-2 light-blue darken-3 white--text"
                  >
                    <div class="text-body-2">Enter a code from your token</div>
                    <v-text-field
                      v-model="activationCode"
                      label="Activation Code"
                      required dark
                      :disabled="progress"
                    ></v-text-field>
                    <v-card-actions class="ml-n2">
                      <v-btn
                        small
                        dark
                        outlined
                        @click="activate"
                        :disabled="
                          progress ||
                          !activationCode ||
                          activationCode.length != 6
                        "
                        >Activate</v-btn
                      >
                      <v-btn
                        small
                        dark
                        outlined
                        @click="displayQRCode = false"
                        :disabled="progress"
                      >
                        Cancel
                      </v-btn>
                    </v-card-actions>
                  </v-card>
                </v-form>
              </div>
              <v-progress-linear
                class="mt-2"
                height="2"
                indeterminate
                :active="progress"
              ></v-progress-linear>
            </v-card>
          </v-dialog>
        </div>
        <div v-else>
          <p class="grey--text">Enrollment is not available at this time.</p>
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
  name: "totp",
  data() {
    return {
      status: undefined,
      factor: undefined,
      enrollQR: undefined,
      activationCode: undefined,
      overlay: false,
      overlayMessage: undefined,
      displayQRCode: false,
      progress: false,
      activationInterval: undefined,
    };
  },
  props: {
    factorCatalog: Object,
    authenticatorName: String,
    push: Boolean,
  },
  watch: {
    factorCatalog: {
      deep: true,
      handler() {
        if (this.factorCatalog.catalog) {
          this.status = this.factorCatalog.catalog.status;
        }
        this.factor = this.factorCatalog.factor;
      },
    },
  },
  methods: {
    emitUpdate() {
      this.$emit("factor-updated", {
        catalog: this.factorCatalog.catalog,
        factor: this.factor,
      });
    },
    async requestApi(options, handler) {
      this.progress = true;
      this.overlay = false;
      this.overlayMessage = undefined;
      try {
        const accessToken = await this.$auth.getAccessToken();
        options.headers = { Authorization: "Bearer " + accessToken };
        const res = await axios(options);
        handler(this, res);
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
    },
    async enroll() {
      const options = {
        method: "POST",
        url:
          this.$config.api +
          "/api/v1/users/" +
          this.$root.$children[0].userinfo.sub +
          "/factors",
        data: {
          factorType: this.factorCatalog.catalog.factorType,
          provider: this.factorCatalog.catalog.provider,
        },
      };
      const handler = async function (self, res) {
        if (res.status == 200) {
          self.factor = res.data;
          if (self.push) {
            if (self.factor._links.poll) {
              self.displayQRCode = true;
              self.enrollQR = res.data._embedded.activation._links.qrcode.href;
              const accessToken = await self.$auth.getAccessToken();
              self.activationInterval = setInterval(
                async () => {
                  try {
                    const pollRes = await axios.post(
                      self.$config.api +
                        "/api/v1/" +
                        self.factor._links.poll.href.split("/api/v1/")[1],
                      null,
                      {
                        headers: { Authorization: "Bearer " + accessToken },
                      }
                    );
                    if (pollRes.data.factorResult) {
                      if (pollRes.data.factorResult === "TIMEOUT") {
                        window.clearInterval(self.activationInterval);
                        self.overlay = true;
                        self.overlayMessage = "Activation request expired.";
                      }
                    } else {
                      self.factor = pollRes.data;
                      window.clearInterval(self.activationInterval);
                      self.emitUpdate();
                      self.progress = false;
                    }
                  } catch (err) {
                    console.log(err);
                    //TODO polling returns a 400 with the errorcode
                    //"FactorAlreadyExists" when complete rather than
                    //the documented factor details
                    window.clearInterval(self.activationInterval);
                  }
                },
                2500,
                accessToken
              );
            }
          } else {
            if (self.factor._links.activate) {
              self.displayQRCode = true;
              self.enrollQR = res.data._embedded.activation._links.qrcode.href;
            }
          }
        }
      };
      await this.requestApi(options, handler);
      if (!this.push) this.progress = false;
    },
    async activate() {
      const options = {
        method: "POST",
        url:
          this.$config.api +
          "/api/v1/" +
          this.factor._links.activate.href.split("/api/v1/")[1],
        data: {
          passCode: this.activationCode,
        },
      };
      const handler = function (self, res) {
        if (res.status == 200) {
          self.factor = res.data;
          self.displayQRCode = false;
          self.$refs.activationform.reset();
          self.emitUpdate();
        }
      };
      await this.requestApi(options, handler);
      this.progress = false;
    },
    async reset() {
      const options = {
        method: "DELETE",
        url:
          this.$config.api +
          "/api/v1/users/" +
          this.$root.$children[0].userinfo.sub +
          "/factors/" +
          this.factor.id,
      };
      const handler = function (self, res) {
        if (res.status == 204) {
          self.factor = undefined;
          self.emitUpdate();
        }
      };
      await this.requestApi(options, handler);
      window.setTimeout(() => {
        this.progress = false;
      }, 1000);
    },
  },
};
</script>