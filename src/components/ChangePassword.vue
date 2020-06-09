<template>
    <v-col cols="4" class="mx-8">
        <h2>Your Password</h2>
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
            <v-card
                    v-if="complexity"
                    class="mx-auto"
                    max-width="400"
                    tile>
                    <v-list-item two-line>
                    <v-list-item-content>
                        <v-list-item-title class="password-rule">Password Requirements</v-list-item-title>
                        <v-list-item-subtitle class="password-rule">Minimum length: {{complexity.minLength}}</v-list-item-subtitle>
                        <v-list-item-subtitle v-if="complexity.hasLower" class="password-rule">One lowercase character</v-list-item-subtitle>
                        <v-list-item-subtitle v-if="complexity.hasUpper" class="password-rule">One uppercase character</v-list-item-subtitle>
                        <v-list-item-subtitle v-if="complexity.hasNumber" class="password-rule">One numberic character</v-list-item-subtitle>
                        <v-list-item-subtitle v-if="complexity.hasSymbol" class="password-rule">One symbol</v-list-item-subtitle>
                        <v-list-item-subtitle
                        v-if="complexity.exclude_userName"
                        class="password-rule">Does not contain  username</v-list-item-subtitle>
                        <v-list-item-subtitle
                        v-if="complexity.exclude_firstName"
                        class="password-rule">Does not contain first name</v-list-item-subtitle>
                        <v-list-item-subtitle
                        v-if="complexity.exclude_lastName"
                        class="password-rule">Does not contain last name</v-list-item-subtitle>
                        <v-list-item-subtitle
                        v-if="complexity.exclude_dictionary"
                        class="password-rule">Not a common password</v-list-item-subtitle>        
                    </v-list-item-content>
                    </v-list-item>
             </v-card>
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

<style scoped>
    .password-rule {
        white-space: break-spaces;
    }
</style>

<script>
import axios from 'axios'

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
            complexity: {
                minLength: undefined,
                hasLower: undefined,
                hasUpper: undefined,
                hasNumber: undefined,
                hasSymbol: undefined,
                exclude_userName: undefined,
                exclude_firstName: undefined,
                exclude_LastName: undefined,
                exclude_dictionary: undefined
            },
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
    created(){
        this.getComplexity()
    },
    methods: {
        async getComplexity(){
            var user = await this.$auth.getUser()
            const groupUrl = this.$config.api + '/api/v1/users/' + user.sub + '/groups'
            const policyUrl = this.$config.api + '/api/v1/policies/?type=PASSWORD'

            try {
                const groups = await axios.get(groupUrl, {headers:{Authorization: 'Bearer '+await this.$auth.getAccessToken()}})
                const policy = await axios.get(policyUrl, {headers:{Authorization: 'Bearer '+await this.$auth.getAccessToken()}})
                //build an array of all the user's group ids
                var usergroups =[]
                groups.data.forEach(element => {
                    usergroups.push(element.id)
                });
                
                //search the policies for the first active policy which is
                //applied to a group of which the user is a member
                //groups are returned in sorted order so first occurance is
                //applied
                for (let i = 0; i < policy.data.length; i++) {
                    const element = policy.data[i];
                    if(element.status != "INACTIVE"){
                        if(element.conditions.people.groups.include.some(r=>usergroups.indexOf(r)>=0)){
                            this.complexity.minLength = element.settings.password.complexity.minLength
                            this.complexity.hasLower = element.settings.password.complexity.minLowerCase > 0
                            this.complexity.hasUpper = element.settings.password.complexity.minUpperCase > 0
                            this.complexity.hasNumber = element.settings.password.complexity.minNumber > 0
                            this.complexity.hasSymbol = element.settings.password.complexity.minSymbol > 0
                            this.complexity.exclude_userName = element.settings.password.complexity.excludeUsername
                            this.complexity.exclude_firstName = element.settings.password.complexity.excludeAttributes.includes("firstName")
                            this.complexity.exclude_LastName = element.settings.password.complexity.excludeAttributes.includes("lastName")
                            this.complexity.exclude_dictionary = element.settings.password.complexity.dictionary.common.exclude
                            break
                        }
                    }                
                }

            } catch(err){
                this.overlayMessage = 'Unable to retrieve password policy'
                window.setTimeout(()=>{
                        this.$refs.form.reset()
                        this.overlay=false
                    }, 600)
            }
        },
        async save() {
            this.saved = false
            this.error = false
            const url = this.$config.api + '/api/v1/users/' + this.$root.$children[0].userinfo.sub + '/credentials/change_password'
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