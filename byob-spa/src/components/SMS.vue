<template>
    <v-col cols="4" class="mx-8">
        <h2>SMS</h2>
        <div v-if="status == 'ACTIVE'">
            You have an enrolled for SMS authentication with {{phoneNumber}}.
            <v-form>
                <v-btn small outlined @click="reset">
                    Remove
                </v-btn>
            </v-form>
        </div>
        <div v-else>
            <div v-if="status == 'NOT_SETUP'">
                Available for enrollment
                <v-form ref="enrollform">
                    <v-text-field
                            v-model="phoneNumber"
                            label="Phone Number"
                            required
                            >
                        </v-text-field>
                    <v-btn small outlined @click="enroll">
                        Begin
                    </v-btn>
                </v-form>
            </div>
            <div v-else>
                <div v-if="status == 'MFA_ENROLL_ACTIVATE'">
                    <v-form ref="activationform">
                        Please enter the code sent to {{phoneNumber}}
                        <v-text-field
                            v-model="activationCode"
                            label="Activation Code"
                            required
                            >
                        </v-text-field>
                        <v-btn small outlined @click="activate">
                            Activate
                        </v-btn>
                    </v-form>
                </div>
                <div v-else>
                    Enrollment is not available at this time.
                </div>
            </div>
        </div>   
        <v-overlay :value="overlay">
                <v-btn>
                    {{overlayMessage}}
                </v-btn>
            </v-overlay> 
    </v-col>
</template>

<script>
import axios from 'axios'

export default {
    factorType: "sms",
    provider: "OKTA",
    name: 'factors',
    data () {
        return {
            overlay: false,
            overlayMessage: undefined,

            factorType: "sms",
            provider: "OKTA",
            factorId: undefined,
            enrollment: undefined,
            status: undefined,

            phoneNumber: undefined,
            activationCode: undefined,
        }
    },    
    created(){
        this.updateCatalog()
        this.updateFactor()
    },
    methods: {
        updateCatalog(){
            if(this.$parent.catalog && this.$parent.catalog.sms){
                this.enrollment = this.$parent.catalog.sms.enrollment
                this.status = this.$parent.catalog.sms.status
            }
        },
        updateFactor(){
            if(this.$parent.factors && this.$parent.factors.sms){
                this.factorId = this.$parent.factors.sms.id
                this.phoneNumber = this.$parent.factors.sms.profile.phoneNumber
            }
        },
        async enroll() {
            const url = this.$config.api + '/api/v1/users/' + this.$root.$children[0].userinfo.sub + '/factors'
            const payload = {
                factorType: this.factorType,
                provider: this.provider ,
                profile: {phoneNumber: this.phoneNumber}
            }
            const accessToken = await this.$auth.getAccessToken()
            try {
                const res = await axios.post(url, payload, {headers: {Authorization: 'Bearer ' + accessToken}})
                if (res.status == 200) {
                    this.status = res.data.status
                    this.factorId = res.data.id
                    this.$refs.enrollform.reset()
                    this.phoneNumber = res.data.profile.phoneNumber
                }
            } catch(err) {
                this.overlay=true
                try {
                    this.overlayMessage = err.response.data.errorCauses[0].errorSummary
                } catch(e) {
                    //lazily handle unexpected responses
                    this.overlayMessage = 'invalid request'
                }
                window.setTimeout(()=>{
                    this.overlay=false
                }, 1000)
            }
        },
        async cancel() {

        },
        async resend() {

        },
        async activate() {
            const url = this.$config.api + '/api/v1/users/' + this.$root.$children[0].userinfo.sub + '/factors/'+this.factorId+'/lifecycle/activate'
            const payload = {
                passCode: this.activationCode
            }
            const accessToken = await this.$auth.getAccessToken()
            try {
                const res = await axios.post(url, payload, {headers: {Authorization: 'Bearer ' + accessToken}})
                this.status = res.data.status
                this.factorid = res.data.id
                this.$refs.activationform.reset()
            } catch(err) {
                this.overlay=true
                try {
                    this.overlayMessage = err.response.data.errorCauses[0].errorSummary
                } catch(e) {
                    // lazily catch unrecognized responses
                    this.overlayMessage = 'Unable to process request. Please re-try'
                }
                window.setTimeout(()=>{
                    this.overlay=false
                }, 1000)
            }
        },
        async reset() {
            const url = this.$config.api + '/api/v1/users/' + this.$root.$children[0].userinfo.sub + '/factors/'+this.factorId
            const accessToken = await this.$auth.getAccessToken()
            this.overlayMessage = undefined
            try {
                await axios.delete(url, {headers: {Authorization: 'Bearer ' + accessToken}})
            } catch(err) {
                this.overlay=true
                try {
                    this.overlayMessage = err.response.data.errorCauses[0].errorSummary
                } catch(e) {
                    //lazily handle unexpected responses
                    this.overlayMessage = 'invalid request'
                }
                window.setTimeout(()=>{
                    this.overlay=false
                }, 1000)
            }
            this.$parent.updateCatalog()
            this.$parent.updateFactors()   
        }
    }    
}
</script>