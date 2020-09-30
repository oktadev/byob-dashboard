<style scoped>
</style>

<template>
  <div v-if="questionEnabled">
    <h4>Password Recovery</h4>
    <div v-if="questionStatus == 'set'">
      <p class="caption">Your current recovery question is:</p>
      <p class="">{{ question }}</p>
      <v-btn small outlined @click="change"> Change </v-btn>
    </div>

    <v-form ref="changeForm" v-model="valid">
      <v-card v-if="questionStatus == 'change'" flat class="py-2">
        <p class="caption">
          Type a new question and answer. Then click <strong>CHANGE</strong>
        </p>
        <v-text-field
          v-model="changeQuestion"
          label="Question"
          required
          filled
          class="py-0 my-0"
        ></v-text-field>
        <v-text-field
          v-model="changeAnswer"
          label="Answer"
          required
          filled
          class="py-0 my-n4"
        ></v-text-field>
        <v-card-actions class="ml-n2">
          <v-btn
            small
            outlined
            @click="beginChange"
            :disabled="
              !changeAnswer ||
              changeAnswer.length <= 0 ||
              !changeQuestion ||
              changeQuestion.length <= 0
            "
          >
            Change</v-btn
          >
          <v-btn small outlined class="ml-2" @click="cancel">Cancel</v-btn>
        </v-card-actions>
      </v-card>
      <v-dialog width="300" v-model="dialog" persistent>
        <v-card flat class="pt-6 pb-1">
          <div class="px-4">
            <p class="caption">
              Please confirm your password to make this change.
            </p>
            <v-text-field
              v-model="password"
              label="Password"
              required
              :type="showPassword ? 'text' : 'password'"
              :append-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
              @click:append="showPassword = !showPassword"
            ></v-text-field>
            <v-card-actions class="ml-n2">
              <v-btn
                small
                outlined
                @click="submitChange"
                :disabled="updating || !password || password.length <= 0"
              >
                Change
              </v-btn>
              <v-btn small outlined @click="cancel" :disabled="updating">
                Cancel
              </v-btn>
            </v-card-actions>
          </div>
          <v-progress-linear
            height="2"
            indeterminate
            :active="updating"
          ></v-progress-linear>
        </v-card>
        <v-overlay :value="overlay">
          <v-btn>
            {{ overlayMessage }}
          </v-btn>
        </v-overlay>
      </v-dialog>
    </v-form>
  </div>
</template>

<script>
import axios from "axios";
export default {
  name: "recoverPasswordFactors",
  data() {
    return {
      user: undefined,
      overlay: false,
      overlayMessage: undefined,
      appUserInfo: undefined,
      questionEnabled: false,
      questionStatus: undefined,
      question: undefined,
      changeQuestion: undefined,
      changeAnswer: undefined,
      password: undefined,
      valid: true,
      showPassword: false,
      dialog: false,
      updating: false,
    };
  },
  created() {
    this.init();
  },
  methods: {
    async init() {
      this.user = this.$root.$children[0].userinfo;
      const accessToken = await this.$auth.getAccessToken();
      try {
        const profileRes = await axios.get(
          this.$config.api + "/api/v1/users/" + this.user.sub,
          {
            headers: { Authorization: "Bearer " + accessToken },
          }
        );
        //this is set first according to policy on sign in
        //if this value is not in the users profile we shouldn't show
        if (profileRes.data.credentials.recovery_question) {
          this.questionEnabled = true;
          this.questionStatus = "set";
          this.question =
            profileRes.data.credentials.recovery_question.question;
        } else {
          this.questionEnabled = false;
        }
      } catch {
        //do nothing
      }
    },

    change() {
      this.questionStatus = "change";
      this.changeQuestion = this.question;
    },

    beginChange() {
      this.dialog = true;
    },

    async submitChange() {
      this.updating = true;
      this.showPassword = false;
      const accessToken = await this.$auth.getAccessToken();
      try {
        await axios.post(
          this.$config.api +
            "/api/v1/users/" +
            this.user.sub +
            "/credentials/change_recovery_question",
          {
            password: { value: this.password },
            recovery_question: {
              question: this.changeQuestion,
              answer: this.changeAnswer,
            },
          },
          {
            headers: { Authorization: "Bearer " + accessToken },
          }
        );
        this.question = this.changeQuestion;
        this.$refs.changeForm.reset();
        this.questionStatus = "set";
      } catch (err) {
        this.overlay = true;
        try {
          this.overlayMessage = err.response.data.errorCauses[0].errorSummary;
        } catch (e) {
          // lazily catch unrecognized responses
          this.overlayMessage = "Unable to process request. Please re-try";
        }
        window.setTimeout(() => {
          this.overlay = false;
        }, 2500);
      }
      this.updating = false;
      this.cancel();
    },

    cancel() {
      this.$refs.changeForm.reset();
      this.questionStatus = "set";
      this.dialog = false;
    },
  },
};
</script>