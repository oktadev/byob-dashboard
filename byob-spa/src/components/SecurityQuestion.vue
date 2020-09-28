<template>
  <div class="py-2 caption">
    <v-card flat outlined class="pa-2">
      <h4>Security Question</h4>
      <div v-if="status == 'ACTIVE'">
        <p class="success--text">
          You have an enrolled for security question authentication.
        </p>
        <v-btn small outlined @click="reset" :disabled="progress">Remove</v-btn>
      </div>
      <div v-else>
        <div v-if="status == 'NOT_SETUP'">
          <div v-if="questions">
            <v-dialog v-model="enrolling" width="500" persistent>
              <v-card class="pt-4 px-0 pb-1">
                <div class="px-4">
                  <v-form ref="questionform">
                    <p>Please select and answer a challenge question.</p>
                    <v-select
                      :items="questions"
                      label="Question"
                      v-model="question"
                      item-text="questionText"
                      item-value="question"
                      outlined
                      :disabled="progress"
                    ></v-select>
                    <v-text-field v-model="answer" label="Answer" required :disabled="progress">
                    </v-text-field>
                    <v-card-actions class="ml-n2">
                      <v-btn small outlined @click="completeEnroll" :disabled="progress">
                        Submit
                      </v-btn>
                      <v-btn small outlined @click="cancel" :disabled="progress"> Cancel </v-btn>
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
            </v-dialog>
          </div>
          <div v-else>
            <p>Available for enrollment</p>
            <v-btn small outlined @click="enroll" :disabled="progress"
              >Setup</v-btn
            >
          </div>
        </div>
        <div v-else class="grey--text">
          Enrollment is not available at this time.
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
  name: "securityQuestion",
  data() {
    return {
      status: undefined,
      factor: undefined,
      enrolling: false,
      overlay: false,
      overlayMessage: undefined,
      questions: undefined,
      question: undefined,
      answer: undefined,
      progress: false,
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
      }, 700);
    },
    async enroll() {
      const options = {
        method: 'GET',
        url: this.$config.api +
          '/api/v1/users/' +
          this.$root.$children[0].userinfo.sub +
          '/factors/questions'
      }
      const handler = function(self, res) {
        if (res.status == 200) {
          self.questions = res.data;
          self.enrolling = true;
        }
      }
      this.requestApi(options, handler);
    },

    async completeEnroll() {
      const options = {
        method: 'POST',
        url: this.$config.api +
          '/api/v1/users/' +
          this.$root.$children[0].userinfo.sub +
          '/factors',
        data: {
          factorType: 'question',
          provider: 'OKTA',
          profile: {
            question: this.question,
            answer: this.answer,
          },
        }
      }
      const handler = function(self, res) {
        if (res.status == 200) {
          self.status = res.data.status;
          self.factor = res.data;
          self.$refs.questionform.reset();
          self.emitUpdate();
        }
      }
      this.requestApi(options, handler);
    },
    async cancel() {
      this.$refs.questionform.reset();
      this.questions = undefined;
    },
    async reset() {
      const options = {
        method: 'DELETE',
        url: this.$config.api +
          '/api/v1/users/' +
          this.$root.$children[0].userinfo.sub +
          '/factors/' + this.factor.id
      }
      const handler = function(self, res) {
        if (res.status == 204) {
          self.factor = undefined;
          self.emitUpdate();
        }
      }
      this.requestApi(options, handler);
    },
  },
};
</script>