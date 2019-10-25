<template>
    <v-container fluid>
        <v-row></v-row>
        <v-tabs vertical v-model="activeTab">
            <v-tab key="profile">Profile</v-tab>
            <v-tab key="security">Security</v-tab>
            <v-tab-item key="profile">
                <Profile
                    :userinfo="userinfo"
                    >
                </Profile>
            </v-tab-item>
            <v-tab-item key="security">
                <ChangePassword>
                </ChangePassword>
            </v-tab-item>
        </v-tabs>
    </v-container>
</template>

<script>
import Profile from '@/components/Profile'
import ChangePassword from '@/components/ChangePassword'

export default {
    name: 'settings',
    components: {
        Profile,
        ChangePassword
    },
    data () {
        return {
            activeTab: this.focusTab
        }
    },
    props: {
        focusTab: Number,
        userinfo: Object
    },
    created() {
    },
    methods: {
    }    
}
</script>