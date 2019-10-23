<template>
    <v-menu
        offset-y offset-overflow
        open-on-hover
        transition="scale-transition"
        >
        <template v-slot:activator="{ on }">
        <v-btn class="mx-2"
            color="primary" outlined
            v-on="on"
        >
            <v-icon left dark>mdi-account</v-icon>
            {{accountName}}
        </v-btn>
        </template>
        <v-card>
            <v-list>
                <v-list-item>
                <v-list-item-avatar 
                    v-if="account.profileUrl"
                    >
                    <img :src="account.profileUrl" alt="profile-pic">
                </v-list-item-avatar>
                <v-list-item-avatar
                    v-if="!account.profileUrl"
                    color="indigo" size="48"
                    >
                    <span class="white--text headline">{{initials}}</span>
                </v-list-item-avatar>
                <v-list-item-content>
                    <v-list-item-title>{{account.name}}</v-list-item-title>
                    <v-list-item-subtitle>{{account.preferred_username}}</v-list-item-subtitle>
                </v-list-item-content>

                </v-list-item>
            </v-list>
            <v-divider></v-divider>
            <v-list>
                <v-list-item>
                <v-btn text light small
                    @click="showProfile"
                    >
                    View/Edit Profile
                </v-btn>
                </v-list-item>
                <v-list-item>
                <v-btn text light small
                    @click="changePassword"
                    >
                    Change Password
                </v-btn>
                </v-list-item>
            </v-list>

            <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn text @click="logout">Logout</v-btn>
            </v-card-actions>
        </v-card>
    </v-menu>   
</template>

<script>
export default {
    name: 'profile-button',
    data () {
        return {
            account: {}
        }
    },
    computed: {
        accountName() {
            return this.account.given_name
        },
        initials() {
            if (!this.account.given_name)
                return ''
            return this.account.given_name.substring(0,1) + this.account.family_name.substring(0,1)
        }
    },
    async created() {
        this.account = await this.$auth.getUser()
    },
    methods: {
        async logout () {
            await this.$auth.logout()
            window.location.href="/"
        },
        showProfile() {
            this.$router.push({
                name: 'settings',
                params: {
                    showProfile: true
                }
            })
        },
        changePassword() {
            this.$router.push({
                name: 'change-password',
                params: {
                    showProfile: true,
                    changePassword: true
                }
            })
        }
    }    
}
</script>