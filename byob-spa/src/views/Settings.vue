<template>
  <v-container fluid>
    <v-row></v-row>
    <v-tabs vertical v-model="activeTab">
      <v-tab key="profile">Profile</v-tab>
      <v-tab key="security">Security</v-tab>
      <v-tab-item key="profile">
        <Profile
          ref="profile"
          v-on:factor-updated="updateFactors($event)"
        ></Profile>
      </v-tab-item>
      <v-tab-item key="security">
        <v-row>
          <v-col cols="6" lg="3" xl="2">
            <ChangePassword />
          </v-col>
          <v-col cols="6" lg="3" xl="2">
            <Factors
              ref="factors"
              v-on:factor-updated="updateProfileFactor()"
            ></Factors>
          </v-col>
        </v-row>
      </v-tab-item>
    </v-tabs>
  </v-container>
</template>

<script>
import Profile from "@/components/Profile";
import ChangePassword from "@/components/ChangePassword";
import Factors from "@/components/Factors";

export default {
  name: "settings",
  components: {
    Profile,
    ChangePassword,
    Factors,
  },
  data() {
    return {
      activeTab: this.focusTab,
    };
  },
  props: {
    focusTab: Number,
  },
  methods: {
    updateProfileFactor() {
      const profileComponent = this.$refs["profile"];
      if (profileComponent) {
        profileComponent.getFactors();
      }
    },
    updateFactors(factor) {
      const factorsComponent = this.$refs["factors"];
      if (factorsComponent) {
        factorsComponent.updateSmsFactor(factor);
      }
    },
  },
};
</script>