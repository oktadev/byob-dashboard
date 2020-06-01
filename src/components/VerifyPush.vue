<template>
    <v-col cols="4" class="mx-8">
        <h2>Okta Verify Push</h2>
        <div v-if="status == 'ACTIVE'">
            You have enrolled Okta Verify Push on {{device}}.
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
                    Please scan the QR code below with Okta Verify
                    <div>
                        <img :src=enrollQR />
                    </div>
                    <v-form>
                        <v-btn small outlined @click="reset">
                            Cancel
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
    factorType: "push",
    provider: "OKTA",
    name: 'factors',
    data () {
        return {
            factorType: "push",
            provider: "OKTA",
            factorId: undefined,
            enrollment: undefined,
            status: undefined,
            vendorName: undefined,
            enrollQR: undefined,
            activationCode: undefined,
            overlay: false,
            overlayMessage: undefined,
            activationInterval: undefined,
            device: undefined
        }
    },    
    created(){
        this.updateCatalog()
        this.updateFactor()
    },
    methods: {
        updateCatalog(){
            if(this.$parent.catalog && this.$parent.catalog.verifyPush){
                this.enrollment = this.$parent.catalog.verifyPush.enrollment
                this.status = this.$parent.catalog.verifyPush.status
                this.vendorName = this.$parent.catalog.verifyPush.vendorName
            }
        },
        updateFactor(){
            if(this.$parent.factors && this.$parent.factors.verifyPush){
                console.log("factor set")
                this.factorId = this.$parent.factors.verifyPush.id
                this.status = this.$parent.factors.verifyPush.status
                this.device = this.$parent.factors.verifyPush.profile.name
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
                    window.setTimeout(()=>{
                        this.overlay=false
                    }, 600)
                    this.status = res.data.status
                    this.factorId = res.data.id
                    this.enrollQR = res.data._embedded.activation._links.qrcode.href
                    this.poll= res.data._links.poll.href

                    //check for when the token is activated
                    this.activationInterval = setInterval(async ()=>{
                        try{
                            const url = this.$config.api + '/api/v1/users/' + this.$root.$children[0].userinfo.sub + '/factors/'+this.factorId+'/lifecycle/activate'
                            const res = await axios.post(url, null, {headers: {Authorization: 'Bearer ' + accessToken, 'Content-Type': 'application/json', 'Accept': 'application/json'}})
                            console.log(res.status)
                            console.log(res.data.factorResult)
                            if(res.data.factorResult){
                                if (res.data.factorResult === "TIMEOUT"){   
                                    window.clearInterval(this.activationInterval)
                                    this.overlay = true
                                    this.overlayMessage = "Activation request expired."
                                }
                            } else{
                                console.log(("success"))
                                window.clearInterval(this.activationInterval)
                                this.$parent.updateCatalog()
                                this.$parent.updateFactors()  
                            }
                        } catch (err){
                            console.log("error")
                            console.log(err)
                            //polling seems to return 400 when complete
                            window.clearInterval(this.activationInterval)
                            this.$parent.updateCatalog()
                            this.$parent.updateFactors()
                        }
                },500, accessToken)
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
             window.clearInterval(this.activationInterval)
            this.$parent.updateCatalog()
            this.$parent.updateFactors()   
        }
    }    
}
</script>