<template>
  <div class="py-0 caption">
    <v-card flat class="pt-4 pb-1 px-0">
      <div class="px-4">
        <p v-if="factor" :class="showPasscodeField ? 'grey--text' : ''">
          Update MFA enrollment with the new number
          <strong>{{ phoneNumber }}</strong
          >?
        </p>
        <p v-else>
          Enroll <strong>{{ phoneNumber }}</strong> in MFA?
        </p>

        <v-form ref="enrollform">
          <div v-if="showPasscodeField">
            <p>
              Please enter the code sent to <strong>{{ factor.profile.phoneNumber }}</strong>
            </p>
            <v-text-field
              v-model="activationCode"
              label="Activation Code"
              required
              :disabled="progress"
            ></v-text-field>
            <p class="warning--text text-subtitle-2"
              v-if="resendAllowed"
            >Did not receive the code? Click on <strong>Resend</strong> to try again.</p>
            <v-card-actions class="ml-n2">
              <v-btn 
                v-if="resendAllowed && factor && factor._links.resend"
                small outlined 
                class="mr-2" 
                @click="resend"
                :disabled="progress"
              >Resend</v-btn>
              <v-btn
                small outlined
                @click="activate"
                :disabled="progress || !activationCode || activationCode.length != 6"
                >Activate</v-btn
              >
              <v-btn
                small outlined
                @click="close"
                :disabled="progress"
                >Cancel</v-btn
              >
            </v-card-actions>
          </div>
          <v-card-actions v-else class="ml-n2">
            <v-btn 
              small outlined 
              @click="enroll"
              :disabled="progress"
            >{{factor ? "Update" : "Enroll"}}</v-btn>
            <v-btn 
              small outlined 
              @click="close"
              :disabled="progress"
            >Close</v-btn>
          </v-card-actions>
        </v-form>
      </div>
      <v-progress-linear 
        class="mt-2" 
        height="2" 
        indeterminate 
        :active="progress"
      ></v-progress-linear>
    </v-card>
    <v-overlay :value="overlay">
      <v-btn>
        {{ overlayMessage }}
      </v-btn>
    </v-overlay>
  </div>
</template>

<script>
import axios from "axios";

export default {
  name: "smsUpdate",
  data() {
    return {
      factor: undefined,
      activationCode: undefined,
      showPasscodeField: false,
      overlay: false,
      overlayMessage: undefined,
      resendAllowed: false,
      resendTimer: undefined,
      progress: false
    };
  },
  props: {
    phoneNumber: String,
    smsFactor: Object,
  },
  created() {
    this.factor = this.smsFactor;
  },
  methods: {
    async requestApi(options, handler) {
      this.progress = true;
      this.overlay = false;
      this.overlayMessage = undefined;
      try {
        const accessToken = await this.$auth.getAccessToken();
        options.headers = { Authorization: "Bearer " + accessToken };
        const res = await axios(options);
        if (handler) handler(this, res);
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
      }, 1500);
    },       
    async close() {
      this.$refs.enrollform.reset();
      this.resendTimer = undefined;
      this.resendAllowed = false;
      this.showPasscodeField = false;
      this.$emit("close");
    },
    async enroll() {
      await this.reset();

      const options = {
        method: 'POST',
        url: this.$config.api +
          '/api/v1/users/' +
          this.$root.$children[0].userinfo.sub +
          '/factors?updatePhone=true',
        data: {
          factorType: 'sms',
          provider: 'OKTA',
          profile: { phoneNumber: this.phoneNumber },
        }
      }
      const handler = function(self, res) {
        if (res.status == 200) {
          self.factor = res.data;
          if (res.data._links.activate) {
            self.showPasscodeField = true;
            self.resendTimer = window.setTimeout(() => {
              if (self.resendTimer) self.resendAllowed = true;
            }, 30000);
            self.progress = false;
          } else {
            self.$emit("close");
          }
        }
      }
      await this.requestApi(options, handler);
    },
    async activate() {
      const options = {
        method: 'POST',
        url: this.$config.api +
          '/api/v1/' +
          this.factor._links.activate.href.split('/api/v1/')[1],
        data: {
          passCode: this.activationCode
        }
      }
      const handler = function(self, res) {
        self.factor = res.data;
        self.$refs.enrollform.reset();
        self.$emit("close");
        self.progress = false;
        self.resendTimer = false;
        self.showPasscodeField = false;
      }
      this.requestApi(options, handler);
    },
    async resend() {
      const options = {
        method: 'POST',
        url: this.$config.api +
          '/api/v1/' +
          this.factor._links.resend[0].href.split('/api/v1/')[1]
      }
      const handler = function(self, res) {
        if (res.status == 200) {
          self.factor = res.data;
        }
      }
      this.requestApi(options, handler);
      this.resendAllowed = false;
      this.resendTimer = window.setTimeout(() => {
        if (this.resendTimer) this.resendAllowed = true;
      }, 30000);
    },
    async reset() {
      if (!this.factor) return;

      const options = {
        method: 'DELETE',
        url: this.$config.api +
          '/api/v1/users/' +
          this.$root.$children[0].userinfo.sub +
          '/factors/' +
          this.factor.id,
      }
      await this.requestApi(options, null);
    },
  },
};
</script>