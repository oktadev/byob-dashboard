<template>
  <v-card class="pa-4 ma-4">
    <h2>Your factors</h2>
    <TotpPush
      authenticatorName="Okta Verify"
      :push="factorCatalog.verifyPush.catalog ? true : false"
      :factorCatalog="factorCatalog.verifyPush.catalog ? factorCatalog.verifyPush : factorCatalog.verify"
      v-on:factor-updated="factorUpdated($event)"
    ></TotpPush>
    <SMS
      :factorCatalog="factorCatalog.sms"
      v-on:factor-updated="factorUpdated($event)"
    ></SMS>
    <TotpPush
      authenticatorName="Google Authenticator"
      :factorCatalog="factorCatalog.googleAuthenticator"
      v-on:factor-updated="factorUpdated($event)"
    ></TotpPush>
    <SecurityQuestion
      :factorCatalog="factorCatalog.securityQuestion"
      v-on:factor-updated="factorUpdated($event)"
    ></SecurityQuestion>
  </v-card>
</template>

<script>
import axios from "axios";
import TotpPush from "@/components/TotpPush";
import SMS from "@/components/SMS";
import SecurityQuestion from "@/components/SecurityQuestion";

export default {
  name: "factors",
  components: {
    TotpPush,
    SMS,
    SecurityQuestion,
  },
  data() {
    return {
      userInfo: undefined,
      factorCatalog: {
        googleAuthenticator: { catalog: undefined, factor: undefined },
        sms: { catalog: undefined, factor: undefined },
        securityQuestion: { catalog: undefined, factor: undefined },
        verify: { catalog: undefined, factor: undefined },
        verifyPush: { catalog: undefined, factor: undefined },
      },
    };
  },
  async created() {
    this.userInfo = this.$root.$children[0].userinfo;
    const accessToken = await this.$auth.getAccessToken();
    this.updateCatalog(accessToken);
    this.updateFactors(accessToken);
  },
  methods: {
    //Retrieve the factors which a user is eligable to enroll
    async updateCatalog(accessToken) {
      try {
        const catalogRes = await axios.get(
          this.$config.api +
            "/api/v1/users/" +
            this.userInfo.sub +
            "/factors/catalog",
          {
            headers: { Authorization: "Bearer " + accessToken },
          }
        );
        catalogRes.data.forEach((cf) => {
          if (cf.factorType == "push" && cf.provider == "OKTA")
            this.factorCatalog.verifyPush.catalog = cf;
          if (cf.factorType == "token:software:totp" && cf.provider == "OKTA")
            this.factorCatalog.verify.catalog = cf;
          if (cf.factorType == "sms" && cf.provider == "OKTA")
            this.factorCatalog.sms.catalog = cf;
          if (cf.factorType == "token:software:totp" && cf.provider == "GOOGLE")
            this.factorCatalog.googleAuthenticator.catalog = cf;
          if (cf.factorType == "question" && cf.provider == "OKTA")
            this.factorCatalog.securityQuestion.catalog = cf;
        });
      } catch {
        // fail silently
      }
    },
    //Retrieve the factors which the user has presently enrolled
    async updateFactors(accessToken) {
      try {
        const enrolledRes = await axios.get(
          this.$config.api + "/api/v1/users/" + this.userInfo.sub + "/factors",
          {
            headers: { Authorization: "Bearer " + accessToken },
          }
        );
        enrolledRes.data.forEach((ff) => {
          if (ff.factorType == "push" && ff.provider == "OKTA")
            this.factorCatalog.verifyPush.factor = ff;
          if (ff.factorType == "token:software:totp" && ff.provider == "OKTA")
            this.factorCatalog.verify.factor = ff;
          if (ff.factorType == "token:software:totp" && ff.provider == "GOOGLE")
            this.factorCatalog.googleAuthenticator.factor = ff;
          if (ff.factorType == "sms" && ff.provider == "OKTA")
            this.factorCatalog.sms.factor = ff;
          if (ff.factorType == "question" && ff.provider == "OKTA")
            this.factorCatalog.securityQuestion.factor = ff;
        });
      } catch {
        // fail silently
      }
    },
    updateSmsFactor(factor) {
      this.factorCatalog.sms.factor = factor;
      if (factor) this.factorCatalog.sms.catalog.status = factor.status;
    },
    async factorUpdated(target) {
      const accessToken = await this.$auth.getAccessToken();
      await this.updateCatalog(accessToken);
      Object.keys(this.factorCatalog).forEach((key) => {
        const item = this.factorCatalog[key].catalog;
        if (
          item &&
          item.factorType == target.catalog.factorType &&
          item.provider == target.catalog.provider
        ) {
          this.factorCatalog[key].factor = target.factor;
        }
      });
      this.$emit("factor-updated", target.factor);
    },
  },
};
</script>
