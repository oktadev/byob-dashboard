<template>
    <v-col cols="3" class="mx-8">
        <v-form
            ref="form"
            v-model="valid"
            >
            <v-row>
                <v-spacer/>
                <v-btn small text
                    @click="save"
                    :disabled="!valid"
                    :color="valid ? 'green' : null"
                    >
                    Change Password
                </v-btn>
            </v-row>

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
        </v-form>
        <v-overlay :value="overlay">
            <v-progress-circular
                indeterminate
                v-if="!saved"
                >
            </v-progress-circular>
            <v-btn
                v-if="saved"
                >
                Password Successfully Updated
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
            account: undefined,
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
                v => !(this.newPassword && this.confirmNewPassword && this.newPassword != this.confirmNewPassword) || "Passwords don't match"
            ],
            processing: false,
            overlay: false,
            saved: false
        }
    },
    computed: {
        claims() {
            let claims = []
            if (this.account) {
                for (let [key, value] of Object.entries(this.account)) {
                    if (!this.reservedFields.includes(key)) {
                        claims.push({
                            key: key,
                            value: value,
                            editable: this.editableFields.includes(key)
                        })
                    }
                }
            }
            return claims
        }
    },
    async created() {
        this.account = await this.$auth.getUser()
    },
    methods: {
        async save() {
            this.overlay=true
            const userId = this.account.sub
            const url = config.proxyApi + '/api/v1/users/' + userId + '/credentials/change_password'
            const payload = {
                oldPassword: {value: this.currentPassword},
                newPassword: {value: this.newPassword}
            }
            const accessToken = await this.$auth.getAccessToken()
            const res = await axios.post(url, payload, {headers: {Authorization: 'Bearer ' + accessToken}})

            if (res.status == 200) {
                this.$refs.form.reset()
                this.saved = true
            }
            window.setTimeout(()=>{
                this.overlay=false
            }, 900)
        }
    }    
}
</script>