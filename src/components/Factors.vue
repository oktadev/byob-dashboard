<template>
    <v-col cols="4" class="mx-8">
        <template v-if="catalog.googleAuthenticator">
            <GoogleAuthenticator></GoogleAuthenticator>
        </template>
    </v-col>        
</template>

<script>
import axios from 'axios'
import GoogleAuthenticator from '@/components/GoogleAuthenticator'

export default {
    name: 'factors',
    components:{
        GoogleAuthenticator
    },
    data () {
        return {
            factors:{
                googleAuthenticator: undefined
            },
            catalog:{
                googleAuthenticator: undefined
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
            this.setCatalog()
            this.setfactors()
        },
        async setCatalog(){
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
                    //handle google factor
                    if(catalogFactors[i].factorType == GoogleAuthenticator.factorType && catalogFactors[i].provider == GoogleAuthenticator.provider){
                        this.catalog.googleAuthenticator = catalogFactors[i]
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
        async setfactors(){
            this.error = false
            const accessToken = await this.$auth.getAccessToken()
            var user = await this.$auth.getUser()
            this.overlayMessage = undefined
            this.overlay=true
            try {
                var url = this.$config.api + '/api/v1/users/' + user.sub + '/factors'
                const enrolledRes = await axios.get(url, {headers: {Authorization: 'Bearer ' + accessToken}})
                var factors = enrolledRes.data
                for(var ii=0; ii<factors.length; ii++){
                    //handle google factor
                    if(factors[ii].factorType == GoogleAuthenticator.factorType && factors[ii].provider == GoogleAuthenticator.provider){
                        this.factors.googleAuthenticator = factors[ii]
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