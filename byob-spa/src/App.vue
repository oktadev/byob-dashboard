<template>
    <v-app>
        <v-app-bar app>
            <v-toolbar-title class="headline text-uppercase">
                <v-icon size="30px" color="primary">mdi-emoticon</v-icon>&nbsp;
                <span class="font-weight-light">Bring Your Own Brand</span>
            </v-toolbar-title>

            <v-spacer></v-spacer>

            <router-link
                tag="button"
                id="login-button"
                to="/login"
                v-if="!loginRedirect && !authenticated"
            >
                <v-btn text>Login</v-btn>
            </router-link>
            <div v-if="authenticated">
                <v-btn text @click="home">
                    <v-icon left dark>mdi-home</v-icon>Home
                </v-btn>
                <ProfileButton v-bind:userinfo="userinfo"></ProfileButton>
                <v-btn v-if="isAdmin" outlined @click="admin"><v-icon></v-icon>Admin</v-btn>
            </div>
        </v-app-bar>
        <v-main>
            <router-view />
        </v-main>
    </v-app>
</template>

<script>
import ProfileButton from "@/components/ProfileButton";

export default {
    name: "App",
    data() {
        return {
            loginRedirect: false,
            authenticated: false,
            userinfo: undefined,
            key: 0
        };
    },
    computed: {
        isAdmin() {
            return this.userinfo && this.userinfo.groups && this.userinfo.groups.includes('SUPERUSERS');
        }
    },
    components: {
        ProfileButton
    },
    async created() {
        await this.appInit();
    },
    watch: {
        // Everytime the route changes, check for auth status
        $route: "isAuthenticated"
    },
    methods: {
        async appInit() {
            if (this.$config.oidc.redirect_uri)
                this.loginRedirect = this.$config.oidc.redirect_uri;
            await this.isAuthenticated();
        },
        async isAuthenticated() {
            this.authenticated = await this.$auth.isAuthenticated();

            if (!this.userinfo) {
                // hacky-hack. Since we're directly updating userinfo. Do not fetch new data because there may be a race-condition and data from Okta could lag the UI
                this.userinfo = await this.$auth.getUser();
            }
        },
        home() {
            if (this.$router.history.current.name !== 'home') {
                this.$router.push({
                    name: "home"
                });
            }
        },
        async admin() {
            const claims = await this.$auth.getUser();
            if (claims.groups && claims.groups.includes('SUPERUSERS')) {
                const win = window.open(this.$config.adminUrl, '_blank');
                win.focus();
            }
        }
    }
};
</script>