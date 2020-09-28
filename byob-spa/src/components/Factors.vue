<template>
  <v-card class="pa-4 ma-4">
    <h2>Your factors</h2>
    <Verify
      :factorCatalog="factorCatalog.verify"
      v-on:factor-updated="factorUpdated($event)"
    ></Verify>
    <!-- <VerifyPush></VerifyPush> -->
    <SMS
      :factorCatalog="factorCatalog.sms"
      v-on:factor-updated="factorUpdated($event)"
    ></SMS>
    <GoogleAuthenticator
      :factorCatalog="factorCatalog.googleAuthenticator"
      v-on:factor-updated="factorUpdated($event)"
    ></GoogleAuthenticator>
    <SecurityQuestion
      :factorCatalog="factorCatalog.securityQuestion"
      v-on:factor-updated="factorUpdated($event)"
    ></SecurityQuestion>
  </v-card>
</template>

<script>
import axios from "axios";
import GoogleAuthenticator from "@/components/GoogleAuthenticator";
import SMS from "@/components/SMS";
import SecurityQuestion from "@/components/SecurityQuestion";
import Verify from "@/components/Verify";
// import VerifyPush from "@/components/VerifyPush";

export default {
  name: "factors",
  components: {
    // VerifyPush,
    Verify,
    GoogleAuthenticator,
    SMS,
    SecurityQuestion,
  },
  data() {
    return {
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
    const accessToken = await this.$auth.getAccessToken();
    this.updateCatalog(accessToken);
    this.updateFactors(accessToken);
  },
  methods: {
    //Retrieve the factors which a user is eligable to enroll
    async updateCatalog(accessToken) {
      try {
        var url =
          this.$config.api +
          "/api/v1/users/" +
          this.$root.$children[0].userinfo.sub +
          "/factors/catalog";
        const catalogRes = await axios.get(url, {
          headers: { Authorization: "Bearer " + accessToken },
        });
        catalogRes.data.forEach((catalogFactor) => {
          if (
            catalogFactor.factorType == Verify.factorType &&
            catalogFactor.provider == Verify.provider
          ) {
            this.factorCatalog.verify.catalog = catalogFactor;
          }
          if (
            catalogFactor.factorType == SMS.factorType &&
            catalogFactor.provider == SMS.provider
          ) {
            this.factorCatalog.sms.catalog = catalogFactor;
          }
          if (
            catalogFactor.factorType == GoogleAuthenticator.factorType &&
            catalogFactor.provider == GoogleAuthenticator.provider
          ) {
            this.factorCatalog.googleAuthenticator.catalog = catalogFactor;
          }
          if (
            catalogFactor.factorType == SecurityQuestion.factorType &&
            catalogFactor.provider == SecurityQuestion.provider
          ) {
            this.factorCatalog.securityQuestion.catalog = catalogFactor;
          }
        });
      } catch {
        // fail silently
      }
    },
    //Retrieve the factors which the user has presently enrolled
    async updateFactors(accessToken) {
      try {
        var url =
          this.$config.api +
          "/api/v1/users/" +
          this.$root.$children[0].userinfo.sub +
          "/factors";
        const enrolledRes = await axios.get(url, {
          headers: { Authorization: "Bearer " + accessToken },
        });
        enrolledRes.data.forEach((factor) => {
          if (
            factor.factorType == Verify.factorType &&
            factor.provider == Verify.provider
          ) {
            this.factorCatalog.verify.factor = factor;
          }
          if (
            factor.factorType == GoogleAuthenticator.factorType &&
            factor.provider == GoogleAuthenticator.provider
          ) {
            this.factorCatalog.googleAuthenticator.factor = factor;
          }
          if (
            factor.factorType == SMS.factorType &&
            factor.provider == SMS.provider
          ) {
            this.factorCatalog.sms.factor = factor;
          }
          if (
            factor.factorType == SecurityQuestion.factorType &&
            factor.provider == SecurityQuestion.provider
          ) {
            this.factorCatalog.securityQuestion.factor = factor;
          }
        });
      } catch {
        // fail silently
      }
    },
    updateSmsFactor(factor) {
      this.factorCatalog.sms.factor = factor;
      if (factor)
        this.factorCatalog.sms.catalog.status = factor.status;
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
