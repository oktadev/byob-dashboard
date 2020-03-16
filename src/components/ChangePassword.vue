<template>
    <v-col cols="4" class="mx-8">
        <v-form
            ref="form"
            v-model="valid"
            >
            <v-text-field
                v-model="currentPassword"
                label="Current Password"
                :rules="currentPasswordRules"
                required
                :type="showCurrentPassword ? 'text' : 'password'"
                :append-icon="showCurrentPassword ? 'mdi-eye' : 'mdi-eye-off'"
                @click:append="showCurrentPassword = !showCurrentPassword"
                >
            </v-text-field>
            <v-text-field
                v-model="newPassword"
                label="New Password"
                :rules="passwordRules"
                required
                :type="showNewPassword ? 'text' : 'password'"
                :append-icon="showNewPassword ? 'mdi-eye' : 'mdi-eye-off'"
                @click:append="showNewPassword = !showNewPassword"
                >
            </v-text-field>
            <v-text-field
                v-model="confirmNewPassword"
                label="Confirm New Password"
                :rules="passwordRules"
                required
                :type="showConfirmPassword ? 'text' : 'password'"
                :append-icon="showConfirmPassword ? 'mdi-eye' : 'mdi-eye-off'"
                @click:append="showConfirmPassword = !showConfirmPassword"
                >
            </v-text-field>
            <v-row>
                <v-btn small outlined
                    @click="save"
                    :disabled="!valid"
                    :color="valid ? 'green' : null"
                    >
                    Change Password
                </v-btn>
            </v-row>                             
        </v-form>
        
        <v-overlay :value="overlay">
            <v-progress-circular
                indeterminate
                v-if="!saved"
                >
            </v-progress-circular>
            <v-btn
                v-if="saved"
                @click="overlay=false"
                :color="error? 'red': ''"
                :outlined="error"
                >
                {{overlayMessage}}&nbsp;
                <v-icon v-if="error">mdi-close</v-icon>
            </v-btn>
        </v-overlay>
    </v-col>        
</template>

<script>
import axios from 'axios'
import config from '@/.config.js'

export default {
    name: 'change-password',
    data () {
        return {
            valid: true,
            currentPassword: undefined,
            newPassword: undefined,
            confirmNewPassword: undefined,
            showCurrentPassword: false,
            showNewPassword: false,
            showConfirmPassword: false,
            currentPasswordRules: [
                v => !!v || 'Current Password is required',
            ],
            passwordRules: [
                v => !!v || 'New Password is required',
                v2 => !!v2 || !(this.newPassword && this.confirmNewPassword && this.newPassword != this.confirmNewPassword) || "Passwords don't match"
            ],
            processing: false,
            overlay: false,
            saved: false,
            overlayMessage: undefined,
            error: false
        }
    },
    methods: {
        async save() {
            this.saved = false
            this.error = false
            const url = config.proxyApi + '/api/v1/users/' + this.$root.$children[0].userinfo.sub + '/credentials/change_password'
            const payload = {
                oldPassword: {value: this.currentPassword},
                newPassword: {value: this.newPassword}
            }
            const accessToken = await this.$auth.getAccessToken()
            this.overlayMessage = undefined
            this.overlay=true
            try {
                const res = await axios.post(url, payload, {headers: {Authorization: 'Bearer ' + accessToken}})
                if (res.status == 200) {
                    this.overlayMessage = 'Password Updated'
                    this.saved = true
                    window.setTimeout(()=>{
                        this.$refs.form.reset()
                        this.overlay=false
                    }, 600)
                }
            } catch(err) {
                try {
                    this.overlayMessage = err.response.data.errorCauses[0].errorSummary
                } catch(e) {
                    //lazily handle unexpected responses
                    this.overlayMessage = 'invalid request'
                }
                this.error = true
                this.saved = true
            }
        }
    }    
}
</script>