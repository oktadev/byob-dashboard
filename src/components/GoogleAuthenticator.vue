<template>
    <div>
        <h2>Google Authenticator</h2>
        <div v-if="status == 'ACTIVE'">
            You have an enrolled Google authenticator.
            <v-form>
                <v-btn small outlined @click="reset">
                    Remove
                </v-btn>
            </v-form>
        </div>
        <div v-else>
            <div v-if="status == 'NOT_SETUP'">
                Available for enrollment
                <v-form>
                    <v-btn small outlined @click="enroll">
                        Begin
                    </v-btn>
                </v-form>
            </div>
            <div v-else>
                <div v-if="status == 'PENDING_ACTIVATION'">
                    Please scan the QR code below with your app
                    <div>
                        <img :src=enrollQR />
                    </div>
                    <v-form ref="activationform">
                        Then enter a code from your token
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
    </div>
</template>

<script>
import axios from 'axios'

export default {
    factorType: "token:software:totp",
    provider: "GOOGLE",
    name: 'factors',
    data () {
        return {
            factorType: "token:software:totp",
            provider: "GOOGLE",
            factorId: undefined,
            enrollment: undefined,
            status: undefined,
            vendorName: undefined,
            links: undefined,
            enrollQR: undefined,
            activationCode: undefined,
            overlay: false,
            overlayMessage: undefined,
        }
    },    
    created(){
        this.init()
    },
    methods: {
        async init() {
            this.enrollment = this.$parent.catalog.googleAuthenticator.enrollment
            this.status = this.$parent.catalog.googleAuthenticator.status
            this.vendorName = this.$parent.catalog.googleAuthenticator.vendorName
            this.links = this.$parent.catalog.googleAuthenticator._links
            if(this.$parent.factors.googleAuthenticator){
                this.factorId = this.$parent.factors.googleAuthenticator.id
            }
        },
        async enroll() {
            const url = this.$config.api + '/api/v1/users/' + this.$root.$children[0].userinfo.sub + '/factors'
            const payload = {
                factorType: this.factorType,
                provider: this.provider 
            }
            const accessToken = await this.$auth.getAccessToken()
            this.overlayMessage = undefined  
            try {
                const res = await axios.post(url, payload, {headers: {Authorization: 'Bearer ' + accessToken}})
                if (res.status == 200) {
                    this.overlayMessage = 'Google Authenticator enrolled, please activate'
                    window.setTimeout(()=>{
                        this.overlay=false
                    }, 600)
                    this.status = res.data.status
                    this.factorId = res.data.id
                    this.enrollQR = res.data._embedded.activation._links.qrcode.href
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
                const res = await axios.delete(url, {headers: {Authorization: 'Bearer ' + accessToken}})
                if (res.status == 204) {
                    this.$parent.setCatalog()
                    this.init()
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
                this.$parent.setCatalog()
                this.init()
            }   
        }
    }    
}
</script>