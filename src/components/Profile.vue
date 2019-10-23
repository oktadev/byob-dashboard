<template>
    <v-col cols="4" class="mx-8">
        <v-form
            ref="form"
            v-model="valid"
            >
            <v-row>
                <v-spacer/>
                <v-btn small text
                    v-if="disabled"
                    @click="disabled=false"
                    >
                    Edit
                </v-btn>
                <v-btn small text
                    v-if="!disabled"
                    @click="save"
                    >
                    Save
                </v-btn>
            </v-row>

            <v-text-field
                v-for="claim in claims"
                v-bind:key="claim.key"
                v-model="claim.value"
                :label="claim.key"
                :disabled="disabled || !claim.editable"
                >
            </v-text-field>
        </v-form>
    </v-col>            
</template>

<script>
export default {
    name: 'profile',
    data () {
        return {
            account: undefined,
            valid: true,
            reservedFields: ['updated_at', 'email_verified'],
            editableFields: ['name', 'email', 'given_name', 'family_name'],
            disabled: true
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
        save() {
            this.disabled=true
            window.setTimeout(()=>{
                alert('TODO: Implement a Save API')
            },500)
        }
    }        
}
</script>