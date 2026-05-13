import mongoose from 'mongoose'

const notificationSchema = new mongoose.Schema({
    receiver_id: {
        type: mongoose.Types.ObjectId
    },

    committee_id: {
        type: mongoose.Types.ObjectId
    },
    request_id: {
        type: mongoose.Types.ObjectId
    },

    user: {
        type: Object
    },

    committee_detail: {
        type: Object
    },

    number_of_committee: {
        type: Number,
        default: 1
    },

    member_id: {
        type: mongoose.Types.ObjectId
    },

    amount: {
        type: Number
    },

    cycle_id: {
        type: mongoose.Types.ObjectId
    },

    payment_type: {
        type: String
    },

    message: {
        type: String
    },

    request_id: {
        type: mongoose.Types.ObjectId,
        default: null
    },

    notification_type: {
        type: Number

        // 1 = join request
        // 2 = join rejected
        // 3 = invite member
        // 4 = payment approval request
        // 5 = payment rejected
        // 6 = refund
        // 7 = join approved
    }

}, { timestamps: true });

const notifications = mongoose.model('notifications', notificationSchema);

export default notifications;