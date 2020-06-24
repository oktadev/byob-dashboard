<style scoped>
.chicklet-label {
  text-align: center;
  color: #a0a0a0;
  font-size: 12px;
  line-height: 13px;
}
</style>

<template>
  <v-container fluid grid-list-xl>
    <draggable
      class="d-flex flex-wrap pa-12 v-card v-sheet theme--light"
      v-model="chicklets"
      @start="drag=true"
      @end="moveComplete"
      :move="moving"
    >
      <v-card flat class="pa-3" v-for="chicklet in chicklets" v-bind:key="chicklet.sortOrder">
        <v-btn
          class="mx-3"
          :width="chickletWidth"
          :height="chickletHeight"
          v-on:click="buttonClick(chicklet.linkUrl)"
        >
          <v-img contain :src="chicklet.logoUrl" :height="logoHeight"></v-img>
        </v-btn>
        <v-card flat class="mx-3 mt-2" :width="chickletWidth">
          <div class="chicklet-label">{{chicklet.label.replace(/^(DAC_)/, "")}}</div>
        </v-card>
      </v-card>
    </draggable>
  </v-container>
</template>

<script>
import axios from "axios";
import draggable from "vuedraggable";
import icons from "@/assets/icons";

export default {
  data() {
    return {
      org: false,
      chickletWidth: "160",
      chickletHeight: "80",
      logoHeight: "33px",
      homeTab: null,
      chicklets: [],
      whatsMoving: false
    };
  },
  components: {
    draggable
  },
  async created() {
    const issuer = this.$config.oidc.issuer;
    this.org = issuer.split("/oauth2")[0];
    await this.getTabs();
    this.getAppLinks();
  },
  methods: {
    async getTabs() {
      const res = await axios.get(this.org + "/api/v1/users/me/home/tabs", {
        withCredentials: true
      });
      const tabs = res.data;
      // sort by sortOrder field
      if (tabs.length > 1) {
        tabs.sort((a, b) => (a.sortOrder > b.sortOrder ? 1 : -1));
      }
      this.homeTab = tabs[0].id;
    },
    async getAppLinks() {
      const res = await axios.get(this.org + "/api/v1/users/me/appLinks", {
        withCredentials: true
      });
      const appLinks = res.data;
      // sort by sortOrder field
      if (appLinks.length > 1) {
        appLinks.sort((a, b) => (a.sortOrder > b.sortOrder ? 1 : -1));
      }

      const overrideIcons = icons.icons;
      overrideIcons.forEach(obj => {
        let i = appLinks.findIndex(link => {
          return link.appInstanceId == obj.id;
        });
        if (i >= 0) {
          if (obj.url && obj.url.length > 0) appLinks[i].logoUrl = obj.url;
          if (obj.label && obj.label.length > 0) appLinks[i].label = obj.label;
        }
      });

      this.chicklets = appLinks;
    },
    buttonClick(href) {
      window.open(href, "_blank");
    },
    moving(evt) {
      this.whatsMoving = evt.draggedContext.element;
    },
    async moveComplete() {
      this.chicklets.forEach(async (chicklet, i) => {
        if (chicklet.id == this.whatsMoving.id) {
          const uri =
            this.org +
            "/api/v1/users/me/home/tabs/" +
            this.homeTab +
            "/items/" +
            chicklet.id;
          const payload = {
            id: chicklet.id,
            resourceType: "urn:okta:resource:appLink",
            sortOrder: i
          };
          axios.put(uri, payload, { withCredentials: true });
        }
      });
      this.whatsMoving = false;
    }
  }
};
</script>