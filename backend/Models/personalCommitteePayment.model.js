import mongoose from 'mongoose';

const personalCommitteePaymentSchema = new mongoose.Schema({
    committee_id: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },

    cycle_no: {
        type: Number,
        required: true
    },

    paid: {
        type: Boolean,
        default: true
    },

    paid_date: {
        type: Date,
        default: Date.now
    }
});

const personalCommitteePayments = mongoose.model(
    'personal_committee_payments',
    personalCommitteePaymentSchema
);

export default personalCommitteePayments;