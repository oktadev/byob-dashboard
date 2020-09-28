<style scoped>
.inline-buttons {
  display: inline-block;
}
</style>

<template>
  <div class="py-2 caption">
    <v-card flat outlined class="pa-2">
      <h4>SMS</h4>
      <div v-if="status == 'ACTIVE'">
        <p class="success--text">
          You have enrolled for SMS authentication with {{ phoneNumber }}.
        </p>
        <v-form>
          <v-btn small outlined 
            @click="reset"
            :disabled="progress"
          >Remove</v-btn>
        </v-form>
      </div>
      <div v-else>
        <div v-if="status == 'NOT_SETUP'">
          <p>Available for enrollment</p>
          <v-btn small outlined 
            @click="setupModal = true"
            :disabled="progress"
          >Setup</v-btn>
          <v-dialog v-model="setupModal" width="300" :persistent="persistent">
            <v-card class="pt-4 pb-1 px-0">
              <div class="px-4">
                <v-form ref="enrollform">
                  <p :class="showPasscodeField ? 'grey--text' : ''">
                    Enter the phone number you want to enroll. Then click the
                    <strong>Setup</strong> button
                  </p>
                  <v-text-field
                    v-model="phoneNumber"
                    label="Phone Number"
                    required
                    :rules="phoneNumberRules"
                    :disabled="progress || showPasscodeField"
                  ></v-text-field>
                  <v-btn
                    small
                    outlined
                    @click="enroll"
                    :disabled="
                      progress || showPasscodeField || !phoneNumber || phoneNumber.length <= 0
                    "
                    >Setup</v-btn
                  >
                  <div v-if="showPasscodeField">
                    <br />
                    <p>Please enter the code sent to <strong>{{ factor.profile.phoneNumber }}</strong></p>
                    <v-text-field
                      v-model="activationCode"
                      label="Activation Code"
                      required
                      :disabled="progress"
                    ></v-text-field>
                    <p class="warning--text text-subtitle-2"
                      v-if="resendAllowed"
                    >Did not receive the code? Click on <strong>Resend</strong> to try again.</p>
                    <div class="inline-buttons">
                      <v-btn 
                        v-if="resendAllowed && factor && factor._links.resend"
                        small outlined 
                        class="mr-2" 
                        @click="resend"
                        :disabled="progress"
                      >Resend</v-btn>
                      <v-btn
                        small
                        outlined
                        class="mr-2" 
                        @click="activate"
                        :disabled="progress || !activationCode || activationCode.length != 6"
                        >Activate</v-btn
                      >
                      <v-btn
                        small
                        outlined
                        @click="cancel"
                        :disabled="progress"
                      >Cancel</v-btn>
                    </div>
                  </div>
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
  name: "sms",
  data() {
    return {
      status: undefined,
      factor: undefined,
      overlay: false,
      overlayMessage: undefined,
      showPasscodeField: false,
      phoneNumber: undefined,
      activationCode: undefined,
      phoneNumberRules: [(v) => !!v || "Phone Number is required"],
      setupModal: false,
      progress: false,
      resendTimer: undefined,
      resendAllowed: false,
      persistent: false
    };
  },
  props: {
    factorCatalog: Object,
  },
  watch: {
    factorCatalog: {
      deep: true,
      handler() {
        this.showPasscodeField = false;
        if (this.factorCatalog.catalog) {
          this.status = this.factorCatalog.catalog.status;
        }
        this.factor = this.factorCatalog.factor;
        if (this.factorCatalog.factor) {
          if (this.status == "NOT_SETUP") this.phoneNumber = undefined;
          else this.phoneNumber = this.factor.profile.phoneNumber;
        }
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
      window.setTimeout(() => {
        this.progress = false;
      }, 1500);
    },
    async enroll() {
      const options = {
        method: 'POST',
        url: this.$config.api +
          '/api/v1/users/' +
          this.$root.$children[0].userinfo.sub +
          '/factors?updatePhone=true',
        data: {
          factorType: this.factorCatalog.catalog.factorType,
          provider: this.factorCatalog.catalog.provider,
          profile: { phoneNumber: this.phoneNumber }
        }
      }
      const handler = function(self, res) {
        if (res.status == 200) {
          self.factor = res.data;
          if (self.factor._links.activate) {
            self.showPasscodeField = true;
            self.resendTimer = window.setTimeout(() => {
              if (self.resendTimer) self.resendAllowed = true;
            }, 30000);
            self.progress = false;
            self.persistent = true;
          } else {
            self.showPasscodeField = false;
            self.$refs.enrollform.reset();
            self.setupModal = false;
            self.emitUpdate();
            self.progress = false;
            self.resendTimer = undefined;
          }
        }
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
          this.factor = res.data;
        }
      }
      this.requestApi(options, handler);
      this.resendAllowed = false;
      this.resendTimer = window.setTimeout(() => {
        if (this.resendTimer) this.resendAllowed = true;
      }, 30000);
    },
    async activate() {
      const options = {
        method: 'POST',
        url: this.$config.api +
          '/api/v1/' +
          this.factor._links.activate.href.split('/api/v1/')[1],
        data: { passCode: this.activationCode }
      }
      const handler = function(self, res) {
        if (res.status == 200) {
          self.factor = res.data;
          self.$refs.enrollform.reset();
          self.setupModal = false;
          self.emitUpdate();
          self.progress = false;
          self.resendTimer = undefined;
          self.persistent = false;
          self.showPasscodeField = false;
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
          self.progress = false;
          self.resendTimer = undefined;
        }
      }
      this.requestApi(options, handler);
    },
    cancel() {
      this.setupModal = false;
      this.$refs.enrollform.reset();
      this.showPasscodeField = false;
      this.resendTimer = undefined;
      this.resendAllowed = false;
      this.persistent = false;
    },
  },
};
</script>