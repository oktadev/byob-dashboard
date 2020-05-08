<template>
  <div>
    <v-dialog v-model="dialog" width="500">
      <v-card>
        <v-card-title class="headline grey lighten-2" primary-title>
          Registration Status
        </v-card-title>

        <v-card-text>
          {{ registrationStatus }}
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="primary" text @click="dialog = false">
            OK
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-container grid-list-md text-xs-center mt-4>
      <v-layout row wrap>
        <v-flex xs12>
          <div class="align-center">
            <h2 class="align-middle">Create Your Account</h2>
            <p></p>
          </div>
          <v-form ref="form" v-model="valid" lazy-validation>
            <v-text-field
              v-model="firstName"
              :counter="100"
              :rules="firstNameRules"
              label="Legal First Name"
              required
            ></v-text-field>

            <v-text-field
              v-model="lastName"
              :counter="100"
              :rules="lastNameRules"
              label="Legal Last Name"
              required
            ></v-text-field>

            <v-text-field
              v-model="email"
              :counter="100"
              :rules="emailRules"
              label="Primary E-mail Address"
              required
            ></v-text-field>

            <v-text-field
              v-model="login"
              :counter="100"
              :rules="loginRules"
              label="Re-Type E-mail Address"
              required
            ></v-text-field>

            <div class="mt-4 mb-4">
              <vue-recaptcha
                :sitekey="config.brand.recaptcha_key"
                @verify="onCaptchaVerified"
                @expired="onCaptchaExpired"
              >
              </vue-recaptcha>
            </div>

            <v-btn
              :disabled="!valid"
              color="success"
              class="mr-4"
              @click="register"
            >
              Register
            </v-btn>

            <v-btn color="secondary" class="mr-4" @click="$router.push('/')">
              Go Home
            </v-btn>
          </v-form>
        </v-flex>
      </v-layout>
    </v-container>
  </div>
</template>

<script>
import axios from "axios";
import config from "@/.config.js";
import VueRecaptcha from "vue-recaptcha";

export default {
  data: () => ({
    registrationStatus: "",
    dialog: false,
    config,
    modal: false,
    valid: true,
    firstName: "",
    firstNameRules: [(v) => !!v || "First Name is required"],
    lastName: "",
    lastNameRules: [(v) => !!v || "Last Name is required"],
    email: "",
    emailRules: [
      (v) => !!v || "E-mail is required",
      (v) => /.+@.+\..+/.test(v) || "E-mail must be valid",
    ],
    login: "",
    loginRules: [
      (v) => !!v || "Login is required",
      (v) => /.+@.+\..+/.test(v) || "Login must be in an e-mail format",
    ],
  }),
  components: {
    VueRecaptcha: VueRecaptcha,
  },
  methods: {
    async register() {
      console.log("TBD: Add registration here");
      let body = {
        firstName: this.firstName,
        lastName: this.lastName,
        login: this.login,
        email: this.email,
        recaptchaToken: this.recaptchaToken,
      };
      let result = await axios.post(
        process.env.VUE_APP_API + "/dashboard/api/v1/users",
        body
      );
      this.registrationStatus = result.data;
      this.dialog = true;
      console.log(result.status);
      console.log(result.data);
    },
    onCaptchaVerified(recaptchaToken) {
      //console.log("onCaptchaVerified: " + recaptchaToken);
      this.recaptchaToken = recaptchaToken;
    },
    onCaptchaExpired() {
      console.log("TBD: onCaptchaExpired");
    },
  },
};
</script>

<style scoped></style>
