<template>
    <v-container>
        <v-row>
            <Profile
                v-if="showProfile">
            </Profile>
            <ChangePassword
                v-if="changePassword">
            </ChangePassword>            
        </v-row>
    </v-container>
</template>

<script>
import Profile from '@/components/Profile'
import ChangePassword from '@/components/ChangePassword'

export default {
    name: 'settings',
    components: {
        Profile, ChangePassword
    },
    data () {
        return {
        }
    },
    props: {
        showProfile: Boolean,
        changePassword: Boolean
    },
    created() {
    },
    methods: {
    }    
}
</script>