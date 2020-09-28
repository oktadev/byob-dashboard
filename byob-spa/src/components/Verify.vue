<template>
  <div class="py-2 caption">
    <v-card flat outlined class="pa-2">
    <h4>Okta Verify</h4>
    <div v-if="status == 'ACTIVE'">
      <p class="success--text">Okta Verify is enrolled.</p>
      <v-btn 
        small outlined 
        @click="reset"
        :disabled="progress"
      >Remove</v-btn>
    </div>
    <div v-else>
      <div v-if="status == 'NOT_SETUP'">
        <p>Available for enrollment</p>
        <v-btn 
          small outlined 
          @click="enroll"
          :disabled="progress"
        >Setup</v-btn>
        <v-dialog v-model="displayQRCode" width="300">
            <v-card class="pt-4 px-0 pb-1">
              <div class="px-4">
                <p>Please scan the QR code below with Okta Verify</p>
                <div>
                    <img :src="enrollQR" />
                </div>
                <v-form ref="activationform">
                    Then enter a code from your token
                    <v-text-field
                        v-model="activationCode"
                        label="Activation Code"
                        required
                        :disabled="progress"
                    ></v-text-field>
                    <v-btn
                      small outlined
                      @click="activate"
                      :disabled="progress || !activationCode || activationCode.length != 6"
                    >Activate</v-btn>
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
  factorType: "token:software:totp",
  provider: "OKTA",
  name: "verify",
  data() {
    return {
      factorType: "token:software:totp",
      provider: "OKTA",
      status: undefined,
      factor: false,
      enrollQR: undefined,
      activationCode: undefined,
      overlay: false,
      overlayMessage: undefined,
      displayQRCode: false,
      progress: false
    };
  },
  props: {
      factorCatalog: Object,
  },
  watch: {
    factorCatalog: {
      deep: true,
      handler() {
        if (this.factorCatalog.catalog) {
          this.status = this.factorCatalog.catalog.status;
        }
        this.factor = this.factorCatalog.factor;
      }
    }
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
      window.setTimeout(() => {
        this.progress = false;
      }, 700);
    },    
    async enroll() {
      const options = {
        method: 'POST',
        url: this.$config.api +
          '/api/v1/users/' +
          this.$root.$children[0].userinfo.sub +
          '/factors',
        data: {
          factorType: this.factorType,
          provider: this.provider
        }
      }
      const handler = function(self, res) {
        if (res.status == 200) {
          self.factor = res.data;
          if (self.factor._links.activate) self.displayQRCode = true;
          self.enrollQR = res.data._embedded.activation._links.qrcode.href;
        }
      }
      this.requestApi(options, handler);
    },
    async activate() {
      const options = {
        method: 'POST',
        url: this.$config.api + '/api/v1/' + this.factor._links.activate.href.split('/api/v1/')[1],
        data: {
          passCode: this.activationCode
        }
      }
      const handler = function(self, res) {
        if (res.status == 200) {
          self.factor = res.data;
          self.displayQRCode = false;
          self.$refs.activationform.reset();
          self.emitUpdate();
        }
      }
      this.requestApi(options, handler);
    },
    async reset() {
      const options = {
        method: 'DELETE',
        url: this.$config.api +
          '/api/v1/users/' +
          this.$root.$children[0].userinfo.sub +
          '/factors/' +
          this.factor.id
      }
      const handler = function(self, res) {
        if (res.status == 204) {
          self.factor = undefined;
          self.emitUpdate();
        }
      }
      this.requestApi(options, handler);
    }
  },
};
</script>