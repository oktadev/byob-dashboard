<template>
    <div>
        <template v-if="catalog.googleAuthenticator">
            <Verify ref="verify"></Verify>
            <VerifyPush ref="verifyPush"></VerifyPush>
            <GoogleAuthenticator ref="googleAuthenticator"></GoogleAuthenticator>
            <SMS ref="sms"></SMS>
            <SecurityQuestion ref="securityQuestion"></SecurityQuestion>
        </template>
    </div>
</template>

<script>
import axios from 'axios'
import GoogleAuthenticator from '@/components/GoogleAuthenticator'
import SMS from '@/components/SMS'
import SecurityQuestion from '@/components/SecurityQuestion'
import Verify from '@/components/Verify'
import VerifyPush from '@/components/VerifyPush'

export default {
    name: 'factors',
    components:{
        VerifyPush,
        Verify,
        GoogleAuthenticator,
        SMS,
        SecurityQuestion
    },
    data () {
        return {
            factors:{
                googleAuthenticator: undefined,
                sms: undefined,
                securityQuestion: undefined,
                verify: undefined,
                verifyPush: undefined
            },
            catalog:{
                googleAuthenticator: undefined,
                sms: undefined,
                securityQuestion: undefined,
                verify: undefined,
                verifyPush: undefined
            },
            processing: false,
            overlay: false,
            saved: false,
            overlayMessage: undefined,
            error: false,
        }
    },
    created(){
        this.init()
    },
    methods: {
        async init() {
            this.updateCatalog()
            this.updateFactors()  
        },
        //Retrieve the factors which a user is eligable to enroll
        async updateCatalog(){
            this.error = false
            const accessToken = await this.$auth.getAccessToken()
            var user = await this.$auth.getUser()
            this.overlayMessage = undefined
            this.overlay=true
            try{
                var url = this.$config.api + '/api/v1/users/' + user.sub + '/factors/catalog'
                const catalogRes = await axios.get(url, {headers: {Authorization: 'Bearer ' + accessToken}})
                var catalogFactors = catalogRes.data
                for(var i=0; i<catalogFactors.length; i++){
                    //handle verify
                    if(catalogFactors[i].factorType == Verify.factorType && catalogFactors[i].provider == Verify.provider){
                        this.catalog.verify = catalogFactors[i]
                        if(this.$refs.verify){
                            this.$refs.verify.updateCatalog()
                        }
                        continue
                    }
                    //handle verify Push
                    if(catalogFactors[i].factorType == VerifyPush.factorType && catalogFactors[i].provider == VerifyPush.provider){
                        this.catalog.verifyPush = catalogFactors[i]
                        if(this.$refs.verifyPush){
                            this.$refs.verifyPush.updateCatalog()
                        }
                        continue
                    }
                    //handle google factor
                    if(catalogFactors[i].factorType == GoogleAuthenticator.factorType && catalogFactors[i].provider == GoogleAuthenticator.provider){
                        this.catalog.googleAuthenticator = catalogFactors[i]
                        if(this.$refs.googleAuthenticator){
                            this.$refs.googleAuthenticator.updateCatalog()
                        }
                        continue
                    }
                    //handle SMS factor
                    if(catalogFactors[i].factorType == SMS.factorType && catalogFactors[i].provider == SMS.provider){
                        this.catalog.sms = catalogFactors[i] 
                        if(this.$refs.sms){
                            this.$refs.sms.updateCatalog()
                        }
                        continue;                        
                    }
                    //handle security question
                    if(catalogFactors[i].factorType == SecurityQuestion.factorType && catalogFactors[i].provider == SecurityQuestion.provider){
                        this.catalog.securityQuestion = catalogFactors[i] 
                        if(this.$refs.securityQuestion){
                            this.$refs.securityQuestion.updateCatalog()
                        }
                        continue;                        
                    }
                }
            }
            catch(err) {
                try {
                    this.overlayMessage = err.response.data.errorCauses[0].errorSummary
                } catch(e) {
                    //lazily handle unexpected responses
                    this.overlayMessage = 'invalid request'
                }
                this.error = true
                this.saved = true
            }   
        },
        //Retrieve the factors which the user has presently enrolled
        async updateFactors(){
            this.error = false
            const accessToken = await this.$auth.getAccessToken()
            var user = await this.$auth.getUser()
            this.overlayMessage = undefined
            this.overlay=true
            try {
                var url = this.$config.api + '/api/v1/users/' + user.sub + '/factors'
                const enrolledRes = await axios.get(url, {headers: {Authorization: 'Bearer ' + accessToken}})
                var factors = enrolledRes.data
                for(var i=0; i<factors.length; i++){
                    //handle verify
                    if(factors[i].factorType == Verify.factorType && factors[i].provider == Verify.provider){
                        this.factors.verify = factors[i]
                        this.$refs.verify.updateFactors()
                        continue
                    }
                    //handle verify push
                    if(factors[i].factorType == VerifyPush.factorType && factors[i].provider == VerifyPush.provider){
                        this.factors.verifyPush = factors[i]
                        this.$refs.verifyPush.updateFactors()
                        continue
                    }
                    //handle google factor
                    if(factors[i].factorType == GoogleAuthenticator.factorType && factors[i].provider == GoogleAuthenticator.provider){
                        console.log(factors[i])
                        this.factors.googleAuthenticator = factors[i]
                        this.$refs.googleAuthenticator.updateFactors()
                        continue
                    }
                    //handle SMS factor
                    if(factors[i].factorType == SMS.factorType && factors[i].provider == SMS.provider){
                        this.factors.sms = factors[i]
                        this.$refs.sms.updateFactor()
                        continue
                    }
                    //handle security question
                    if(factors[i].factorType == SecurityQuestion.factorType && factors[i].provider == SecurityQuestion.provider){
                        this.factors.securityQuestion = factors[i] 
                        if(this.$refs.securityQuestion){
                            this.$refs.securityQuestion.updateFactor()
                        }
                        continue;                        
                    }
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
