import mongoose from "mongoose";

const joinRequestSchema = new mongoose.Schema({
    committee_id: mongoose.Schema.Types.ObjectId,
    admin_id: mongoose.Schema.Types.ObjectId,
    user_id: mongoose.Schema.Types.ObjectId,
    status: {
        type: String,
        default: "pending"
    },
    number_of_committee: {
        type: Number,
        default: 1
    }
});

const JoinRequest = mongoose.model("join_requests", joinRequestSchema);
export default JoinRequest;