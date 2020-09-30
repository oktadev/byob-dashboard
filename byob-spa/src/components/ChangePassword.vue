<style scoped>
.password-rule {
  white-space: break-spaces;
}
</style>

<template>
  <v-card class="pa-4 ma-4">
    <h2>Your Password</h2>
    <p class="text-subtitle-2 grey--text">
      Enter your current password and new password. Then click
      <strong>CHANGE PASSWORD</strong>
    </p>
    <v-form ref="form" v-model="valid">
      <v-text-field
        v-model="currentPassword"
        label="Current Password"
        :rules="currentPasswordRules"
        required
        :type="showCurrentPassword ? 'text' : 'password'"
        :append-icon="showCurrentPassword ? 'mdi-eye' : 'mdi-eye-off'"
        @click:append="showCurrentPassword = !showCurrentPassword"
      >
      </v-text-field>
      <v-card
        class="mx-auto"
        max-width="400"
        tile
        flat
        outlined
        color="grey lighten-3"
      >
        <v-list-item two-line>
          <v-list-item-content>
            <v-list-item-title>Password Requirements</v-list-item-title>
            <div v-if="ready" class="password-rule">
              <v-list-item-subtitle v-if="complexity.hasLower"
                >Minimum length:
                {{ complexity.minLength }}</v-list-item-subtitle
              >
              <v-list-item-subtitle v-if="complexity.hasLower"
                >One lowercase character</v-list-item-subtitle
              >
              <v-list-item-subtitle v-if="complexity.hasUpper"
                >One uppercase character</v-list-item-subtitle
              >
              <v-list-item-subtitle v-if="complexity.hasNumber"
                >One numeric (0-9) character</v-list-item-subtitle
              >
              <v-list-item-subtitle v-if="complexity.hasSymbol"
                >One symbol (e.g., !@#$%^&*)</v-list-item-subtitle
              >
              <v-list-item-subtitle v-if="complexity.exclude_userName"
                >Does not contain username</v-list-item-subtitle
              >
              <v-list-item-subtitle v-if="complexity.exclude_firstName"
                >Does not contain first name</v-list-item-subtitle
              >
              <v-list-item-subtitle v-if="complexity.exclude_lastName"
                >Does not contain last name</v-list-item-subtitle
              >
              <v-list-item-subtitle v-if="complexity.exclude_dictionary"
                >Not a common password</v-list-item-subtitle
              >
            </div>
            <div v-else>
              <p class="mt-2 caption grey--text">
                Fetching password complexity rules...
              </p>
              <v-progress-linear
                class="mt-n4 pt-0"
                color="grey"
                indeterminate
                height="1"
              ></v-progress-linear>
            </div>
          </v-list-item-content>
        </v-list-item>
      </v-card>
      <v-text-field
        v-model="newPassword"
        label="New Password"
        :rules="passwordRules"
        required
        :type="showNewPassword ? 'text' : 'password'"
        :append-icon="showNewPassword ? 'mdi-eye' : 'mdi-eye-off'"
        @click:append="showNewPassword = !showNewPassword"
      >
      </v-text-field>
      <v-text-field
        v-model="confirmNewPassword"
        label="Confirm New Password"
        :rules="passwordConfirmationRules"
        required
        :type="showConfirmPassword ? 'text' : 'password'"
        :append-icon="showConfirmPassword ? 'mdi-eye' : 'mdi-eye-off'"
        @click:append="showConfirmPassword = !showConfirmPassword"
      >
      </v-text-field>
      <v-row>
        <v-btn
          small
          outlined
          class="ml-3"
          @click="save"
          :disabled="!valid"
          :color="valid ? 'green' : null"
        >
          Change Password
        </v-btn>
      </v-row>
    </v-form>

    <v-overlay :value="overlay">
      <v-progress-circular indeterminate v-if="!saved"> </v-progress-circular>
      <v-btn
        v-if="saved"
        @click="overlay = false"
        :color="error ? 'red' : ''"
        :outlined="error"
      >
        {{ overlayMessage }}&nbsp;
        <v-icon v-if="error">mdi-close</v-icon>
      </v-btn>
    </v-overlay>
    <br />
    <hr />
    <br />
    <PasswordRecoveryFactors />
  </v-card>
</template>

<script>
import axios from "axios";
import PasswordRecoveryFactors from "@/components/PasswordRecoveryFactors";

export default {
  name: "change-password",
  data() {
    return {
      valid: true,
      currentPassword: undefined,
      newPassword: undefined,
      confirmNewPassword: undefined,
      showCurrentPassword: false,
      showNewPassword: false,
      showConfirmPassword: false,
      complexity: {},
      ready: false,
      currentPasswordRules: [(v) => !!v || "Current password is required"],
      passwordRules: [
        (v) => !!v || "New password is required",
        (v) =>
          (v && v.length > this.complexity.minLength) ||
          "Password must be " + this.complexity.minLength + " characters.",
        (v) =>
          !this.complexity.hasLower ||
          (v && !!v.match("[a-z]+")) ||
          "Password must contain one lower case letter.",
        (v) =>
          !this.complexity.hasUpper ||
          (v && !!v.match("[A-Z]+")) ||
          "Password must contain one upper case letter.",
        (v) =>
          !this.complexity.hasNumber ||
          (v && !!v.match("[0-9]+")) ||
          "Password must contain one numeric character.",
        (v) =>
          !this.complexity.hasSymbol ||
          (v && !!v.match("!|@|#|\\$|%|\\^|&|\\*")) ||
          "Password must contain one symbol character.",
        (v) =>
          !this.complexity.exclude_userName ||
          (v && v.match(this.complexity.exclude_userName_value) == null) ||
          "Password must not contain username.",
        (v) =>
          !this.complexity.exclude_firstName ||
          (v && v.match(this.complexity.exclude_firstName_value) == null) ||
          "Password must not contain given name.",
        (v) =>
          !this.complexity.exclude_lastName ||
          (v && v.match(this.complexity.exclude_lastName_value) == null) ||
          "Password must not contain family name.",
      ],
      passwordConfirmationRules: [
        (v) => !!v || "Password confirmation is required",
        (v) => (v && v == this.newPassword) || "Passwords don't match",
      ],
      processing: false,
      overlay: false,
      saved: false,
      overlayMessage: undefined,
      error: false,
    };
  },
  components: {
    PasswordRecoveryFactors,
  },
  created() {
    this.getComplexity();
  },
  methods: {
    async getComplexity() {
      const user = this.$root.$children[0].userinfo;
      const groupUrl =
        this.$config.api + "/api/v1/users/" + user.sub + "/groups";
      const policyUrl = this.$config.api + "/api/v1/policies/?type=PASSWORD";

      try {
        const groups = await axios.get(groupUrl, {
          headers: {
            Authorization: "Bearer " + (await this.$auth.getAccessToken()),
          },
        });
        const policy = await axios.get(policyUrl, {
          headers: {
            Authorization: "Bearer " + (await this.$auth.getAccessToken()),
          },
        });
        //build an array of all the user's group ids
        let usergroups = [];
        groups.data.forEach((element) => {
          usergroups.push(element.id);
        });

        //search the policies for the first active policy which is
        //applied to a group of which the user is a member
        //groups are returned in sorted order so first occurance is
        //applied
        for (let i = 0; i < policy.data.length; i++) {
          const element = policy.data[i];
          if (element.status != "INACTIVE") {
            if (
              element.conditions.people.groups.include.some(
                (r) => usergroups.indexOf(r) >= 0
              )
            ) {
              this.complexity.minLength =
                element.settings.password.complexity.minLength;
              this.complexity.hasLower =
                element.settings.password.complexity.minLowerCase > 0;
              this.complexity.hasUpper =
                element.settings.password.complexity.minUpperCase > 0;
              this.complexity.hasNumber =
                element.settings.password.complexity.minNumber > 0;
              this.complexity.hasSymbol =
                element.settings.password.complexity.minSymbol > 0;

              this.complexity.exclude_userName =
                element.settings.password.complexity.excludeUsername;
              this.complexity.exclude_firstName = element.settings.password.complexity.excludeAttributes.includes(
                "firstName"
              );
              this.complexity.exclude_lastName = element.settings.password.complexity.excludeAttributes.includes(
                "lastName"
              );
              this.complexity.exclude_dictionary =
                element.settings.password.complexity.dictionary.common.exclude;

              if (
                this.complexity.exclude_userName ||
                this.complexity.exclude_lastName ||
                this.complexity.exclude_firstName
              ) {
                var userinfo = await this.$auth.getUser();
                this.complexity.exclude_userName_value =
                  userinfo.preferred_username;
                this.complexity.exclude_firstName_value = userinfo.given_name;
                this.complexity.exclude_lastName_value = userinfo.family_name;
              }

              break;
            }
          }
        }
      } catch (err) {
        this.overlayMessage = "Unable to retrieve password policy";
        window.setTimeout(() => {
          this.$refs.form.reset();
          this.overlay = false;
        }, 600);
      }
      this.ready = true;
    },
    async save() {
      this.saved = false;
      this.error = false;
      const url =
        this.$config.api +
        "/api/v1/users/" +
        this.$root.$children[0].userinfo.sub +
        "/credentials/change_password";
      const payload = {
        oldPassword: { value: this.currentPassword },
        newPassword: { value: this.newPassword },
      };
      const accessToken = await this.$auth.getAccessToken();
      this.overlayMessage = undefined;
      this.overlay = true;
      try {
        const res = await axios.post(url, payload, {
          headers: { Authorization: "Bearer " + accessToken },
        });
        if (res.status == 200) {
          this.overlayMessage = "Password Updated";
          this.saved = true;
          window.setTimeout(() => {
            this.$refs.form.reset();
            this.overlay = false;
          }, 600);
        }
      } catch (err) {
        try {
          this.overlayMessage = err.response.data.errorCauses[0].errorSummary;
        } catch (e) {
          //lazily handle unexpected responses
          this.overlayMessage = "invalid request";
        }
        this.error = true;
        this.saved = true;
      }
    },
  },
};
</script>