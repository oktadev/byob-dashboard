<template>
  <div class="py-2 caption">
    <v-card flat outlined class="pa-2">
    <h4>Security Question</h4>
    <div v-if="status == 'ACTIVE'">
      You have an enrolled for security question authentication.
      <v-form>
        <v-btn small outlined @click="reset"> Remove </v-btn>
      </v-form>
    </div>
    <div v-else>
      <div v-if="status == 'NOT_SETUP'">
        <div v-if="questions">
          <v-form ref="questionform">
            Please select and answer a challenge question.
            <v-select
              :items="questions"
              label="Question"
              v-model="question"
              item-text="questionText"
              item-value="question"
              outlined
            ></v-select>
            <v-text-field v-model="answer" label="Answer" required>
            </v-text-field>
            <v-btn small outlined @click="completeEnroll"> Submit </v-btn>
            <v-btn small outlined @click="cancel"> Cancel </v-btn>
          </v-form>
        </div>
        <div v-else>
          Available for enrollment
          <v-form ref="enrollform">
            <v-btn small outlined @click="enroll"> Begin </v-btn>
          </v-form>
        </div>
      </div>
      <div v-else>
        <div v-if="status == 'MFA_ENROLL_ACTIVATE'">
          <v-form ref="activationform">
            Please enter the code sent to {{ phoneNumber }}
            <v-text-field
              v-model="activationCode"
              label="Activation Code"
              required
            >
            </v-text-field>
            <v-btn small outlined @click="activate"> Activate </v-btn>
          </v-form>
        </div>
        <div v-else class="grey--text">Enrollment is not available at this time.</div>
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
  factorType: "question",
  provider: "OKTA",
  name: "securityQuestion",
  data() {
    return {
      overlay: false,
      overlayMessage: undefined,

      factorType: "question",
      provider: "OKTA",
      factorId: undefined,
      enrollment: undefined,
      status: undefined,

      questions: undefined,
      question: undefined,
      answer: undefined,
    };
  },
  created() {
    this.updateCatalog();
    this.updateFactor();
  },
  methods: {
    updateCatalog() {
      if (this.$parent.catalog && this.$parent.catalog.securityQuestion) {
        this.enrollment = this.$parent.catalog.securityQuestion.enrollment;
        this.status = this.$parent.catalog.securityQuestion.status;
      }
    },
    updateFactor() {
      if (this.$parent.factors && this.$parent.factors.securityQuestion) {
        this.factorId = this.$parent.factors.securityQuestion.id;
      }
    },
    async enroll() {
      const url =
        this.$config.api +
        "/api/v1/users/" +
        this.$root.$children[0].userinfo.sub +
        "/factors/questions";
      const accessToken = await this.$auth.getAccessToken();
      try {
        const res = await axios.get(url, {
          headers: { Authorization: "Bearer " + accessToken },
        });
        if (res.status == 200) {
          this.questions = res.data;
        }
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
        }, 1000);
      }
    },

    async completeEnroll() {
      const url =
        this.$config.api +
        "/api/v1/users/" +
        this.$root.$children[0].userinfo.sub +
        "/factors";
      const payload = {
        factorType: this.factorType,
        provider: this.provider,
        profile: {
          question: this.question,
          answer: this.answer,
        },
      };
      const accessToken = await this.$auth.getAccessToken();
      try {
        const res = await axios.post(url, payload, {
          headers: { Authorization: "Bearer " + accessToken },
        });
        if (res.status == 200) {
          this.status = res.data.status;
          this.factorId = res.data.id;
          this.$refs.questionform.reset();
        }
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
        }, 1000);
      }
      this.$parent.updateCatalog();
      this.$parent.updateFactors();
    },
    async cancel() {
      this.questions = undefined;
    },
    async reset() {
      const url =
        this.$config.api +
        "/api/v1/users/" +
        this.$root.$children[0].userinfo.sub +
        "/factors/" +
        this.factorId;
      const accessToken = await this.$auth.getAccessToken();
      this.overlayMessage = undefined;
      try {
        await axios.delete(url, {
          headers: { Authorization: "Bearer " + accessToken },
        });
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
        }, 1000);
      }
      this.$parent.updateCatalog();
      this.$parent.updateFactors();
    },
  },
};
</script>