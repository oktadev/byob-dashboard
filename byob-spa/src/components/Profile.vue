<template>
  <v-row>
    <v-col cols="5" class="mx-8">
      <v-form ref="form" v-model="valid">
        <v-row>
          <v-spacer />
          <v-btn small outlined v-if="saved" @click="saved = false">Edit</v-btn>
          <v-btn small outlined color="green" v-if="!saved" @click="save"
            >Save</v-btn
          >
        </v-row>
        <template v-for="claim in claims">
          <div v-if="claim.mfaFunction" :key="claim.key">
            <v-row :key="'row-' + claim.key">
              <v-col>
                <v-text-field
                  v-model="claim.value"
                  :key="claim.key"
                  :label="claim.label"
                  :disabled="saved || !claim.editable"
                ></v-text-field>
              </v-col>
              <v-col
                class="mt-6 caption success--text"
                v-if="claim.mfaEnrolled"
              >
                <v-icon small color="success" class="mr-2">mdi-check</v-icon>MFA
                enrolled
              </v-col>
            </v-row>
          </div>
          <v-text-field
            v-else
            :key="claim.key"
            v-model="claim.value"
            :label="claim.label"
            :disabled="saved || !claim.editable"
          ></v-text-field>
        </template>
      </v-form>
      <v-overlay :value="overlay">
        <v-progress-circular indeterminate v-if="!saved"></v-progress-circular>
        <v-btn v-if="saved">{{ overlayMessage }}</v-btn>
      </v-overlay>
    </v-col>
    <v-col cols="2">
      <v-avatar color="indigo" size="240">
        <span
          v-if="!appUserInfo || !appUserInfo.profile"
          class="white--text headline"
          >{{ initials }}</span
        >
        <img
          v-if="appUserInfo && appUserInfo.profile"
          :src="profilePic"
          alt="profile-pic"
        />
      </v-avatar>
    </v-col>
    <v-dialog v-model="updateMfa" width="300" persistent>
      <SMS
        :phoneNumber="newPhoneNumber"
        :smsFactor="smsFactor"
        v-on:close="enrollComplete"
      ></SMS>
    </v-dialog>
  </v-row>
</template>

<script>
import axios from "axios";
import SMS from "@/components/SmsUpdate";

export default {
  name: "profile",
  data() {
    return {
      valid: true,
      invisibleFields: [
        // list of claims in the idToken that we don't want to display
        "updated_at",
        "email_verified",
        "sub",
        "zoneinfo",
      ],
      fieldMeta: [
        // list of claims in the idToken and their behavior in the UI
        {
          name: "preferred_username",
          label: "Username",
          profileField: "login",
          editable: false,
        },
        {
          name: "profile",
          label: "Profile Pic Url",
          profileField: "profileUrl",
          editable: true,
        },
        {
          name: "email",
          label: "Email",
          profileField: "email",
          editable: true,
        },
        {
          name: "given_name",
          label: "First Name",
          profileField: "firstName",
          editable: true,
        },
        {
          name: "family_name",
          label: "Last Name",
          profileField: "lastName",
          editable: true,
        },
        {
          name: "MobilePhone",
          label: "Phone",
          profileField: "mobilePhone",
          editable: true,
          formatMask: "",
          mfa: true,
        },
      ],
      saved: true,
      overlay: false,
      overlayMessage: undefined,
      claims: [],
      appUserInfo: this.$root.$children[0].userinfo,
      enrolledFactors: undefined,
      smsFactor: undefined,
      updateMfa: false,
      newPhoneNumber: undefined,
    };
  },
  components: {
    SMS,
  },
  computed: {
    initials() {
      if (!this.appUserInfo || !this.appUserInfo.given_name) return "";
      return (
        this.appUserInfo.given_name.substring(0, 1) +
        this.appUserInfo.family_name.substring(0, 1)
      );
    },
    profilePic() {
      for (let claim of this.claims) {
        if (claim.key == "profile") return claim.value;
      }
      return null;
    },
  },
  created() {
    this.init();
  },
  methods: {
    async init() {
      let claims = [];
      // A browser refresh here could prevent userinfo to be loaded in from App.
      // But we can easily fetch it using getUser()
      if (!this.appUserInfo) this.appUserInfo = await this.$auth.getUser();

      for (let [key, value] of Object.entries(this.appUserInfo)) {
        // Don't show the "invisible" fields
        if (!this.invisibleFields.includes(key)) {
          claims.push({
            key: key,
            value: value,
            valueOld: value,
            editable: this.isEditableField(key),
            mfaFunction: this.mfaFunction(key),
            mfaEnrolled: false,
            label: this.customFieldLabel(key),
          });
        }
      }
      this.claims = claims;
      this.getFactors();
    },
    async getFactors() {
      const accessToken = await this.$auth.getAccessToken();
      try {
        const res = await axios.get(
          this.$config.api +
            "/api/v1/users/" +
            this.appUserInfo.sub +
            "/factors",
          {
            headers: { Authorization: "Bearer " + accessToken },
          }
        );
        if (res.status == 200) {
          this.enrolledFactors = res.data;
          const smsFactors = this.enrolledFactors.filter((factor) => {
            return (
              factor.factorType == "sms" &&
              factor.provider == "OKTA" &&
              factor.status == "ACTIVE"
            );
          });
          if (smsFactors.length > 0) {
            this.smsFactor = smsFactors[0];
            if (this.smsFactor.profile.phoneNumber) {
              this.claims
                .filter((claim) => {
                  return claim.mfaFunction;
                })
                .forEach((claim) => {
                  if (
                    this.substringLast10(claim.value) ==
                    this.substringLast10(this.smsFactor.profile.phoneNumber)
                  )
                    claim.mfaEnrolled = true;
                  else claim.mfaEnrolled = false;
                });
            }
          } else {
            this.smsFactor = undefined;
            this.claims.forEach((claim) => {
              claim.mfaEnrolled = false;
            });
          }
        }
      } catch {
        //fail silently
      }
    },
    substringLast10(value) {
      return value.substr(value.length - 10);
    },
    isEditableField(claim) {
      return (
        this.fieldMeta.filter((field) => {
          return field.name == claim && field.editable;
        }).length > 0
      );
    },
    customFieldLabel(claim) {
      try {
        return this.fieldMeta.filter((field) => {
          return field.name == claim;
        })[0].label;
      } catch {
        return claim;
      }
    },
    mfaFunction(claim) {
      return (
        this.fieldMeta.filter((field) => {
          return field.name == claim && field.mfa;
        }).length > 0
      );
    },
    async save() {
      this.overlay = true;
      this.saved = false;
      this.overlayMessage = undefined;

      let profile = {};
      this.fieldMeta.forEach((field) => {
        let index = this.claims.findIndex((claim) => {
          return claim.key == field.name;
        });
        if (index >= 0) profile[field.profileField] = this.claims[index].value;
      });
      const payload = {
        profile: profile,
      };
      const accessToken = await this.$auth.getAccessToken();
      const url = this.$config.api + "/api/v1/users/" + this.appUserInfo.sub;
      try {
        const res = await axios.post(url, payload, {
          headers: { Authorization: "Bearer " + accessToken },
        });

        // post processing to synch up the data everywhere
        if (res.status == 200) {
          this.overlayMessage = "Profile Updated";

          this.claims.forEach((claim) => {
            // must make sure to update the userinfo object's attributes
            this.appUserInfo[claim.key] = claim.value;

            // phone number was updated. Display option to enroll in MFA
            if (claim.mfaFunction && claim.value != claim.valueOld) {
              this.newPhoneNumber = claim.value;
              if (
                this.smsFactor &&
                this.substringLast10(this.newPhoneNumber) ==
                  this.substringLast10(this.smsFactor.profile.phoneNumber)
              ) {
                this.getFactors();
              } else {
                this.updateMfa = true;
              }
            }
            claim.valueOld = claim.value;
          });

          // update the "name" claim, in case first/last names have changed
          this.appUserInfo.name =
            this.appUserInfo.given_name + " " + this.appUserInfo.family_name;
          this.claims[
            this.claims.findIndex((claim) => {
              return claim.key == "name";
            })
          ].value = this.appUserInfo.name;

          // finally update the root userinfo object
          this.$root.$children[0].userinfo = this.appUserInfo;
        }
      } catch (err) {
        try {
          this.overlayMessage = err.response.data.errorCauses[0].errorSummary;
        } catch (e) {
          // lazily catch unrecognized responses
          this.overlayMessage = "Unable to process request. Please re-try";
        }
        window.setTimeout(() => {}, 2500);
      }
      this.saved = true;
      this.overlay = false;
    },
    async enrollComplete() {
      await this.getFactors();
      this.updateMfa = false;
      this.$emit("factor-updated", this.smsFactor);
    },
  },
};
</script>