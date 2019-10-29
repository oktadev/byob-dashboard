<template>
    <v-row>
        <v-col cols="5" class="mx-8">
            <v-form
                ref="form"
                v-model="valid"
                >
                <v-row>
                    <v-spacer/>
                    <v-btn small outlined
                        v-if="saved"
                        @click="saved=false"
                        >
                        Edit
                    </v-btn>
                    <v-btn small outlined color="green"
                        v-if="!saved"
                        @click="save"
                        >
                        Save
                    </v-btn>
                </v-row>

                <v-text-field
                    v-for="claim in claims"
                    v-bind:key="claim.key"
                    v-model="claim.value"
                    :label="customFieldLabel(claim.key)"
                    :disabled="saved || !claim.editable"
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
                    {{overlayMessage}}
                </v-btn>
            </v-overlay>
        </v-col>
        <v-col cols="2">
            <v-avatar color="indigo" size="240">
                <span v-if="!appUserInfo.profile" class="white--text headline">{{initials}}</span>
                <img v-if="appUserInfo.profile" :src="profilePic" alt="profile-pic">
            </v-avatar>
        </v-col>
    </v-row>
</template>

<script>
import axios from 'axios'
import config from '@/.config.js'

export default {
    name: 'profile',
    data () {
        return {
            valid: true,
            invisibleFields: ['updated_at', 'email_verified', 'sub', 'zoneinfo'],
            editableFields: [
                {name: 'profile', label: 'Profile Pic Url', profileField: 'profileUrl'}, 
                {name: 'email', label: 'Email', profileField: 'email'}, 
                {name: 'given_name', label: 'First Name', profileField: 'firstName'}, 
                {name: 'family_name', label: 'Last Name', profileField: 'lastName'}
            ],
            saved: true,
            overlay: false,
            overlayMessage: undefined,
            claims: [],
            appUserInfo: this.$root.$children[0].userinfo
        }
    },
    computed: {
        initials() {
            if (!this.appUserInfo || !this.appUserInfo.given_name)
                return ''
            return this.appUserInfo.given_name.substring(0,1) + this.appUserInfo.family_name.substring(0,1)
        },
        profilePic() {
            for (let claim of this.claims) {
                if (claim.key=='profile') return claim.value
            }
            return null
        }
    },
    created() {
        this.init()
    },
    methods: {
        init() {
            let claims = []
            if (this.appUserInfo) {
                for (let [key, value] of Object.entries(this.appUserInfo)) {
                    if (!this.invisibleFields.includes(key)) {
                        claims.push({
                            key: key,
                            value: value,
                            editable: this.isEditableField(key)
                        })
                    }
                }
            }
            this.claims = claims     
        },
        isEditableField(claim) {
            for (let field of this.editableFields) {
                if (field.name == claim) return true
            }
            return false
        },
        customFieldLabel(claim) {
            for (let field of this.editableFields) {
                if (field.name == claim) return field.label
            }
            return claim
        },
        async save() {
            this.overlay = true
            this.saved = false
            this.overlayMessage = undefined

            let profile = {}
            for (let field of this.editableFields) {
                let index = this.claims.findIndex((claim)=>{
                    return claim.key == field.name
                })
                if (index >= 0)
                    profile[field.profileField] = this.claims[index].value
            }
            const payload = {
                profile: profile
            }
            const accessToken = await this.$auth.getAccessToken()
            const url = config.proxyApi + '/api/v1/users/' + this.appUserInfo.sub
            try {
                const res = await axios.post(url, payload, {headers: {Authorization: 'Bearer ' + accessToken}})
                if (res.status == 200) {
                    this.overlayMessage = 'Profile Updated'

                    // must make sure to update the userinfo object's attributes
                    this.claims.forEach((claim)=>{
                        this.appUserInfo[claim.key] = claim.value
                    })
                    // update the "name" claim, in case first/last names have changed
                    this.appUserInfo.name = this.appUserInfo.given_name + ' ' + this.appUserInfo.family_name
                    this.claims[this.claims.findIndex((claim)=>{return claim.key=='name'})].value = this.appUserInfo.name
                    this.$root.$children[0].userinfo = this.appUserInfo
                }
            } catch(err) {
                try {
                    this.overlayMessage = err.response.data.errorCauses[0].errorSummary
                } catch(e) {
                    // lazily catch unrecognized responses
                    this.overlayMessage = 'Unable to process request. Please re-try'
                }
                window.setTimeout(()=>{}, 900)
            }
            this.saved = true
            this.overlay = false
        }
    }        
}
</script>