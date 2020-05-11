<template>
    <v-col cols="4" class="mx-8">
        <h2>WebAuthn</h2>
        <div v-if="status == 'ACTIVE'">
            You have enrolled WebAuthn.
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
                        Register
                    </v-btn>
                </v-form>
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
    factorType: "webauth",
    provider: "FIDO",
    name: 'factors',
    data () {
        return {
            factorType: "webauthn",
            provider: "FIDO",
            supported: false,
            factorId: undefined,
            enrollment: undefined,
            status: undefined,
            overlay: false,
            overlayMessage: undefined,
        }
    },    
    created(){
        // Check in browser supports Credential Management
        this.supported = 'credentials' in navigator;

        if (this.supported) {
            this.updateCatalog()
            this.updateFactor()
        } else {
            console.log("Credential Management is not supported in browser");
        }
    },
    methods: {
        binToStr(bin) {
            return btoa(new Uint8Array(bin).reduce(
            (s, byte) => s + String.fromCharCode(byte), ''
            ));
        },
        strToBin(str) {
            return Uint8Array.from(atob(this.base64UrlSafeToBase64(str)), c => c.charCodeAt(0));
        },
        base64UrlSafeToBase64(str) {
            return str.replace(new RegExp('_', 'g'), '/').replace(new RegExp('-', 'g'), '+');
        },
        updateCatalog(){
            if(this.$parent.catalog && this.$parent.catalog.googleAuthenticator){
                this.enrollment = this.$parent.catalog.googleAuthenticator.enrollment
                this.status = this.$parent.catalog.googleAuthenticator.status
                this.vendorName = this.$parent.catalog.googleAuthenticator.vendorName
            }
        },
        updateFactor(){
            if(this.$parent.factors && this.$parent.factors.googleAuthenticator){
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
                console.log("Got response", JSON.stringify(res.data))
                if (res.status == 200) {
                    window.setTimeout(()=>{
                        this.overlay=false
                    }, 600)
                    this.status = res.data.status
                    this.factorId = res.data.id

                    // Convert activation object's challenge and user id from string to binary
                    let activation = res.data._embedded.activation;
                    activation.challenge = this.strToBin(activation.challenge);
                    activation.user.id = this.strToBin(activation.user.id)

                    // Create Credentials in CredMan
                    const newCredential = await navigator.credentials.create( {
                        publicKey: activation
                    });


                    // Get attestation and clientData and convert from binary to string
                    let attestation = this.binToStr(newCredential.response.attestationObject);
                    console.log("attestation", JSON.stringify(attestation));

                    let clientData = this.binToStr(newCredential.response.clientDataJSON);
                                        console.log("clientData", JSON.stringify(clientData));

                    // Activate WebAuthn factor by verifying the attestation and client Data
                    const url2 = this.$config.api + "/api/v1/users/" + this.$root.$children[0].userinfo.sub + "/factors/" + this.factorId + "/lifecycle/activate"
                    const payload2 = {
                        attestation,
                        clientData
                    }
                    const res2 = await axios.post(url2, payload2, {headers: {Authorization: 'Bearer ' + accessToken}})

                    console.log("Activation Response", JSON.stringify(res2.data))

                    if (res2.status == 200) {
                        this.status = res2.data.status;
                    }
                }
            } catch(err) {
                console.log("err", err);
                console.log("Error", JSON.stringify(err.response.data))
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
            this.$parent.updateCatalog()
            this.$parent.updateFactors()   
        }
    }    
}
</script>