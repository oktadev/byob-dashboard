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
        <v-card v-if="userinfo">
            <v-list>
                <v-list-item>
                <v-list-item-avatar 
                    v-if="userinfo.profile"
                    >
                    <img :src="userinfo.profile" alt="profile-pic">
                </v-list-item-avatar>
                <v-list-item-avatar
                    v-if="!userinfo.profile"
                    color="indigo" size="48"
                    >
                    <span class="white--text headline">{{initials}}</span>
                </v-list-item-avatar>
                <v-list-item-content>
                    <v-list-item-title>{{userinfo.name}}</v-list-item-title>
                    <v-list-item-subtitle>{{userinfo.preferred_username}}</v-list-item-subtitle>
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
        return {}
    },
    props: {
        userinfo: Object
    },
    computed: {
        accountName() {
            return this.userinfo ? this.userinfo.given_name : ''
        },
        initials() {
            if (!this.userinfo || !this.userinfo.given_name)
                return ''
            return this.userinfo.given_name.substring(0,1) + this.userinfo.family_name.substring(0,1)
        }
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
                    userinfo: this.userinfo,
                    focusTab: 0
                }
            })
        },
        changePassword() {
            this.$router.push({
                name: 'settings',
                params: {
                    userinfo: this.userinfo,
                    focusTab: 1
                }
            })
        }
    }    
}
</script>