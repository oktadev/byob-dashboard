<template>
    <v-col v-if="questionEnabled" cols="4" class="mx-8">
        <h2>Password Recovery</h2>
        <div v-if="questionStatus == 'set'">
            <p>You will be asked to answer the following question to reset your
            password:</p>
            <p class="recovery-question">{{question}}</p>
            <v-form>
                <v-btn small outlined @click="change">
                    Change
                </v-btn>
            </v-form>
        </div>
        <div v-if="questionStatus == 'change'">
            <v-form>
                 <v-text-field
                    v-model="changeQuestion"
                    label="Question"
                    required
                    >
                </v-text-field>
                <v-text-field
                    v-model="changeAnswer"
                    label="Answer"
                    required
                    >
                </v-text-field>
                <v-btn small outlined @click="beginChange">
                    Change
                </v-btn>
                <v-btn small outlined @click="cancel">
                    Cancel
                </v-btn>
            </v-form>
        </div>
        <div v-if="questionStatus == 'verify'">
            <p>Please confirm your password to make this change.</p>
                <v-text-field
                    v-model="password"
                    label="Password"
                    required
                    type='password'
                    >
                </v-text-field>
                <v-btn small outlined @click="submitChange">
                    Change
                </v-btn>
                <v-btn small outlined @click="cancel">
                    Cancel
                </v-btn>
        </div>
        <v-overlay :value="overlay">
            <v-btn>
                {{overlayMessage}}
            </v-btn>
        </v-overlay> 
    </v-col>
</template>

<style scoped>
.recovery-question{
    font-weight: bold;
}
</style>

<script>
import axios from 'axios'
export default {
    name: 'recoverPasswordFactors',
    data () {
        return {
            overlay: false,
            overlayMessage: undefined,
            appUserInfo: undefined,
            questionEnabled: false,
            questionStatus: undefined,
            question: undefined,
            changeQuestion:undefined,
            changeAnswer: undefined,
            password: undefined
        }
    },    
    created(){
        this.init()
    },
    methods: {
        async init() {
            var user = await this.$auth.getUser()
            var accessToken = await this.$auth.getAccessToken()
            try{
                var url = this.$config.api + '/api/v1/users/' + user.sub
                const profileRes = await axios.get(url, {headers: {Authorization: 'Bearer ' + accessToken}})
                //this is set first according to policy on sign in
                //if this value is not in the users profile we shouldn't show
                if(profileRes.data.credentials.recovery_question){
                    this.questionEnabled = true
                    this.questionStatus = 'set'
                    this.question = profileRes.data.credentials.recovery_question.question
                }
                else {
                    this.questionEnabled = false
                }
            } catch(err) {
                console.log(err)
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

        change(){
            this.questionStatus = 'change',
            this.changeQuestion = this.question
        },

        beginChange(){
            this.questionStatus = 'verify'
        },

        async submitChange(){
            var user = await this.$auth.getUser()
            var accessToken = await this.$auth.getAccessToken()

            const url = this.$config.api + '/api/v1/users/' + user.sub + '/credentials/change_recovery_question'
            const payload = {
                "password": { "value": this.password }, 
                "recovery_question": {
                "question" : this.changeQuestion,
                "answer": this.changeAnswer
                } 
            }
            try {
                await axios.post(url, payload, {headers: {Authorization: 'Bearer ' + accessToken}})
                this.question = this.changeQuestion
                this.changeQuestion = undefined
                this.changeAnswer = undefined
                this.password = undefined
                this.questionStatus = 'set'
            } catch(err) {
                console.log(err)
                this.overlay=true
                try {
                    this.overlayMessage = err.response.data.errorCauses[0].errorSummary
                } catch(e) {
                    // lazily catch unrecognized responses
                    this.overlayMessage = 'Unable to process request. Please re-try'
                }
                window.setTimeout(()=>{
                    this.overlay=false
                }, 2000)
            }
        },

        cancel(){
            this.changeQuestion = undefined
            this.changeAnswer = undefined
            this.password = undefined
            this.questionStatus = 'set'
        }
    }
}
</script>