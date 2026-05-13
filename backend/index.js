import mongoose from 'mongoose'
import express from 'express'
import dotenv from 'dotenv'
import cors from 'cors'
import jwt from 'jsonwebtoken'
import cookieParser from 'cookie-parser'
import upload from './MiddleWare/multer.middleware.js'
import usermodel from './Models/user.model.js'
import personalCommittee from './Models/personalCommittee.model.js'
import sharedCommittee from './Models/shared_Committee.model.js'
import committeemember from './Models/committee_member.model.js'
import committeecycle from './Models/committee_cycle.model.js'
import notificationmodel from './Models/notification.model.js'
import committee_payment from './Models/committee_payment.model.js'
import committee_cycles from './Models/committee_cycle.model.js'
import sharedcommittees from './Models/shared_Committee.model.js'
import committee_members from './Models/committee_member.model.js'
import cycle_biddings from './Models/cycle_bidding.model.js'
import users from './Models/user.model.js'
import committee_refund from './Models/committee_refund.model.js'
import JoinRequest from './Models/joinRequest.model.js';
import personalCommitteePayments from './Models/personalCommitteePayment.model.js';

const app = express();
dotenv.config();
app.use(express.json());
app.use(cors({
    origin: 'http://localhost:5173',
    credentials: true
}
));
app.use('/Images', express.static('Images'));
app.use(cookieParser());//used to read cookies 


app.listen(process.env.PORT, () => {
    console.log("Server Started");
    committee_winners();
})

mongoose.connect(process.env.DBURL).then(() => {
    console.log("DataBase Connected");

})

app.get('/', (req, res) => {
    res.send("testing");
})

app.post('/create_user', upload.single('profile_img'), async (req, res) => {
    try {
        let data = req.body;
        let singlefile = req.file;
        if (singlefile) {
            const newuser = new usermodel({
                name: data.name,
                password: data.password,
                monthly_income: data.monthly_income,
                phoneno: data.phoneno,
                profile_img: `/Images/${singlefile.filename}`
            });
            await newuser.save();
            res.send("user Created");
        }
        else {
            const newuser = new usermodel({
                name: data.name,
                password: data.password,
                monthly_income: data.monthly_income,
                phoneno: data.phoneno,
            });
            await newuser.save();
            res.send("user Created");
        }

    }
    catch (error) {
        if (error.code === 11000) {
            return res.send("account on this number already exists");
        }
        res.send(`Error in Creating New User`);
    }
})



app.post('/login', async (req, res) => {
    try {
        let temp = req.body;
        let data = await usermodel.findOne({ 'phoneno': temp.phoneno, 'password': temp.password });
        if (data) {
            const token = jwt.sign({ "phoneno": temp.phoneno }, 'shhh');
            res.cookie("phoneno", token);//cookie name and data
            return res.send("User Found");
        }
        else {
            let tempphone = await usermodel.findOne({ "phoneno": temp.phoneno });
            if (tempphone) {
                res.send("Wrong Password");
            }
            else {
                res.send("No Account Found on This Number");
            }
        }
    }
    catch (error) {
        res.send(`Error ${error}`);
    }
})



app.post('/verify-login', (req, res) => {
    let acookie = req.cookies.phoneno;
    if (!acookie) {
        return res.send("No Cookie Found");
    }
    try {

        let error = jwt.verify(acookie, 'shhh');
        res.send("Authorized");
    }
    catch (error) {
        res.send("UnAuthorized =Cookie Expired or Altered");
    }
})

app.get('/logout', (req, res) => {
    try {
        res.clearCookie("phoneno");
        return res.send('Loging Out');
    }
    catch (error) {
        res.send("Error Loging Out");
    }
})


app.get('/getprofile', async (req, res) => {

    try {
        let cokie = req.cookies.phoneno;//take saved cookie mobilephoneno
        if (!cokie) {
            return res.send("No Cookie Found");
        }
        let decode = jwt.verify(cokie, 'shhh'); //decode={ phoneno: '123', iat: 1769410131 }
        const phoneno = decode.phoneno;
        let data = await usermodel.findOne({ 'phoneno': phoneno });
        res.send(data);
    }
    catch (error) {
        res.send(`Error occured=${error}`);
    }

})


app.put('/deleteprofileimg', async (req, res) => {
    try {
        let id = req.body._id;
        let data = await usermodel.updateOne({ "_id": id }, { $set: { "profile_img": "Signup/default-profile-image.jpg" } });
        res.send('profileimg deleted');
    }
    catch (error) {
        res.send({ "error": `${error} profileimg not deleted` });
    }
})

app.put('/updateprofileimg', upload.single('profile_img'), async (req, res) => {
    try {
        let id = req.body._id;
        let profile_img = req.file
        await usermodel.updateOne({ "_id": id }, { profile_img: `/Images/${singlefile.filename}` });
        res.send('profileimg updated');
    }
    catch (error) {
        res.send({ "error": `${error} profileimg not deleted` });
    }
})


app.put('/update-user/:id', upload.single('profile_img'), async (req, res) => {
    try {
        let data = req.body;
        let singlefile = req.file;
        if (singlefile) {
            await usermodel.updateOne(
                { '_id': req.params.id }
                ,
                {//user change file
                    name: data.name,
                    password: data.password,
                    monthly_income: data.monthly_income,
                    phoneno: data.phoneno,
                    profile_img: `/Images/${file.filename}`
                });
            let token = jwt.sign({ 'phoneno': data.phoneno }, 'shhh');
            res.clearCookie("phoneno");
            res.cookie('phoneno', token);
            res.send("updated");
        }
        else {
            await usermodel.updateOne(
                { '_id': req.params.id }
                ,
                {//if user dont chage the file
                    name: data.name,
                    password: data.password,
                    monthly_income: data.monthly_income,
                    phoneno: data.phoneno,
                });
            let token = jwt.sign({ 'phoneno': data.phoneno }, 'shhh');
            res.clearCookie("phoneno");
            res.cookie('phoneno', token);
            res.send("updated");
        }
    }
    catch (error) {
        res.send(error);
    }
})


app.post('/personal-committee', async (req, res) => {
    try {
        let data = req.body;
        const newpersonalcommittee = new personalCommittee(data);
        await newpersonalcommittee.save();
        res.send("Committee Created");
    }
    catch (error) {
        res.send(`error connured=${error}`);
    }
})


let dates_calculator_function = (sd, dd, dg, cn) => {
    //start_date==sd   deadline_date===dd  days_gap===dg   cyclenumber>>number_of_member in committee==cn  
    let cycledate = new Date(sd);
    cycledate.setDate(cycledate.getDate() + ((cn - 1) * dg));
    let deadline_date = new Date(cycledate);
    deadline_date.setDate(cycledate.getDate() + dd);
    let end_date = new Date(cycledate);
    end_date.setDate(cycledate.getDate() + dg);
    return { "start_date": cycledate, "end_date": end_date, "deadline_date": deadline_date }

}
app.post('/shared-committee', async (req, res) => {
    try {
        let data = req.body;
        //creating shared committee
        const newsharedcommittee = new sharedCommittee(data);
        await newsharedcommittee.save();
        res.send("Committee Created");
    }
    catch (error) {
        res.send(`error connured=${error}`);
    }
})



app.get('/invite-member/:phoneno', async (req, res) => {
    try {
        let number = req.params.phoneno;
        let singleuser = await usermodel.findOne({ 'phoneno': number });
        res.send(singleuser);
    }
    catch (error) {
        console.log(error);
    }
})

app.post("/join-request", async (req, res) => {

    try {

        const {
            committee_id,
            admin_id,
            user_id,
            number_of_committee
        } = req.body;

        const existing = await JoinRequest.findOne({
            committee_id,
            user_id,
            status: "pending"
        });

        if (existing) {
            return res.send("Already requested");
        }

        const request = new JoinRequest({
            committee_id,
            admin_id,
            user_id,
            number_of_committee
        });

        await request.save();

        // =========================
        // GET USER
        // =========================

        const user = await usermodel.findById(user_id);

        // =========================
        // GET COMMITTEE
        // =========================

        const committee =
            await sharedCommittee.findById(
                committee_id
            );

        // =========================
        // CREATE NOTIFICATION
        // =========================

        const notification =
            new notificationmodel({

                receiver_id: admin_id,

                committee_id,

                user: user,

                number_of_committee,

                request_id: request._id,

                committee_detail: committee,

                message:
                    `${user.name} wants to join "${committee.committee_name}" with ${number_of_committee} committees.`,

                notification_type: 1
            });

        await notification.save();

        res.send("Request sent successfully");

    } catch (error) {

        console.log(error);

        res.send("Error: " + error);
    }
});

app.get('/join-requests/:adminId', async (req, res) => {
    try {
        const adminId = req.params.adminId;

        const data = await JoinRequest.aggregate([
            {
                $match: {
                    admin_id: new mongoose.Types.ObjectId(adminId),
                    status: "pending"
                }
            },
            {
                $lookup: {
                    from: "users",
                    localField: "user_id",
                    foreignField: "_id",
                    as: "user_detail"
                }
            },
            {
                $unwind: "$user_detail"
            },
            {
                $lookup: {
                    from: "shared_committees",
                    localField: "committee_id",
                    foreignField: "_id",
                    as: "committee_detail"
                }
            },
            {
                $unwind: "$committee_detail"
            }
        ]);

        res.send(data);
    } catch (error) {
        res.send(error);
    }
});

app.post('/approve-join-request/:id', async (req, res) => {

    try {

        const notification = await notificationmodel.findById(req.params.id);

        if (!notification) {
            return res.send("Notification not found");
        }

        const request = await JoinRequest.findById(
            notification.request_id
        );

        if (!request) {
            return res.send("Request not found");
        }

        let committee_details = await sharedCommittee.findOne({
            _id: request.committee_id
        });

        if (!committee_details.enrollment_period) {
            return res.send("Enrollment Closed");
        }

        for (let i = 0; i < request.number_of_committee; i++) {

            await sharedCommittee.updateOne(
                { _id: request.committee_id },
                { $inc: { number_of_member: 1 } }
            );

            committee_details = await sharedCommittee.findOne({
                _id: request.committee_id
            });

            const newmember = new committeemember({
                committee_id: request.committee_id,
                user_id: request.user_id,
                turn_number: committee_details.number_of_member
            });

            let nmember = await newmember.save();

            let calculated_dates = dates_calculator_function(
                committee_details.start_date,
                committee_details.deadline_day,
                committee_details.days_gap,
                committee_details.number_of_member
            );

            const newcycle = new committeecycle({
                committee_id: request.committee_id,
                cycle_number: committee_details.number_of_member,
                start_date: calculated_dates.start_date,
                end_date: calculated_dates.end_date,
                deadline_date: calculated_dates.deadline_date
            });

            let ncycle = await newcycle.save();

            let allCycles = await committee_cycles.find({
                committee_id: request.committee_id
            });

            // payments for new member
            for (let cycle of allCycles) {

                let exists = await committee_payment.findOne({
                    member_id: nmember._id,
                    cycle_id: cycle._id
                });

                if (!exists) {

                    await new committee_payment({
                        member_id: nmember._id,
                        cycle_id: cycle._id
                    }).save();
                }
            }

            // payments for existing members
            let existingMembers = await committeemember.find({
                committee_id: request.committee_id,
                _id: { $ne: nmember._id },
                active: true
            });

            for (let member of existingMembers) {

                let exists = await committee_payment.findOne({
                    member_id: member._id,
                    cycle_id: ncycle._id
                });

                if (!exists) {

                    await new committee_payment({
                        member_id: member._id,
                        cycle_id: ncycle._id
                    }).save();
                }
            }
        }

        // notify user approved
        await notificationmodel.create({

            receiver_id: request.user_id,

            message:
                `Your request to join ${committee_details.committee_name} was approved`,

            notification_type: 7
        });

        // delete request
        await JoinRequest.deleteOne({
            _id: request._id
        });

        // delete notification
        await notificationmodel.deleteOne({
            _id: notification._id
        });

        res.send("Approved");

    } catch (error) {

        console.log(error);
        res.send(error.toString());
    }
});

app.post("/invite-member", async (req, res) => {
    const { committee_id, admin_id, user_id } = req.body;

    const notification = new notificationmodel({
        committee_id,
        admin_id,
        user_id,
        type: "invite"
    });

    await notification.save();

    res.send("Invitation sent");
});

app.post("/accept-invite/:id", async (req, res) => {
    const notif = await notificationmodel.findById(req.params.id);

    await axios.post("http://localhost:3000/accept-request/" + req.params.id, {
        committee_id: notif.committee_id,
        user_id: notif.user_id,
        number_of_committee: 1
    });

    await notificationmodel.deleteOne({ _id: req.params.id });

    res.send("Joined");
});

app.post('/reject-join-request/:id', async (req, res) => {

    try {

        const notification = await notificationmodel.findById(
            req.params.id
        );

        if (!notification) {
            return res.send("Notification not found");
        }

        const request = await JoinRequest.findById(
            notification.request_id
        );

        if (request) {

            await notificationmodel.create({

                receiver_id: request.user_id,

                message:
                    `Your request to join ${notification.committee_detail.committee_name} was rejected`,

                notification_type: 2
            });

            await JoinRequest.deleteOne({
                _id: request._id
            });
        }

        await notificationmodel.deleteOne({
            _id: notification._id
        });

        res.send("Rejected");

    } catch (error) {

        console.log(error);
        res.send(error.toString());
    }
});

app.get('/get-all-joined-committees/:id', async (req, res) => {
    try {
        let user_id = new mongoose.Types.ObjectId(req.params.id);
        let data = await committeemember.aggregate([//joining committee_members with committee_details table
            {
                $match: {
                    user_id: user_id,
                    active: true
                }
            }
            ,
            {
                $lookup: {
                    from: "shared_committees",
                    localField: "committee_id",   ///join two table happens here
                    foreignField: "_id",
                    as: "committee_details"
                }
            },
            {
                $match: {
                    'committee_details': { $ne: [] } ///this is written after the join so work on the resulting joined table only.
                }
            },
            {
                $unwind: '$committee_details'
            }

        ]);
        res.send(data);
    }
    catch (error) {
        console.log(error);
    }

})
app.get('/get-all-committees-of-admin/:id', async (req, res) => {
    let id = req.params.id;
    let data = await sharedcommittees.find({ 'admin_id': id });
    res.send(data);
})

app.get('/get-all-personal-committees/:id', async (req, res) => {
    let data = await personalCommittee.find({
        committee_admin_id: req.params.id
    });
    res.send(data);
})

app.get('/get-all-admin-committees/:id', async (req, res) => {
    try {
        const id = req.params.id;

        const shared = await sharedcommittees.find({
            admin_id: id
        });

        const personal = await personalCommittee.find({
            committee_admin_id: id
        });

        res.json({
            shared: shared,
            personal: personal
        });

    } catch (e) {
        res.status(500).json({ error: e.toString() });
    }
});


app.post('/personal-pay', async (req, res) => {
    try {
        const { committee_id, cycle_no } = req.body;

        const alreadyPaid =
            await personalCommitteePayments.findOne({
                committee_id: committee_id,
                cycle_no: cycle_no
            });

        if (alreadyPaid) {
            return res.json({
                message: "Already Paid"
            });
        }

        await personalCommitteePayments.create({
            committee_id,
            cycle_no
        });

        res.json({
            message: "Payment Added"
        });

    } catch (e) {
        res.status(500).json({
            error: e.toString()
        });
    }
});

app.get('/personal-progress/:id', async (req, res) => {
    try {
        const id = req.params.id;

        const committee =
            await personalCommittee.findById(id);

        const paidCount =
            await personalCommitteePayments.countDocuments({
                committee_id: id
            });

        const total = committee.total_cycle;

        res.json({
            paid: paidCount,
            total: total,
            remaining: total - paidCount,
            saved: paidCount * committee.amount,
            nextCycle: paidCount + 1
        });

    } catch (e) {
        res.status(500).json({
            error: e.toString()
        });
    }
});

////////////////////////////////////////////////// Committee details /////////////////////////////////////////////////
app.post('/this-month-dues', async (req, res) => {
    const today = new Date(req.body.today);
    today.setUTCHours(0, 0, 0, 0);

    const committee_id = new mongoose.Types.ObjectId(req.body.committee_id);
    const member_id = new mongoose.Types.ObjectId(req.body.committee_member_id);//joining the committee_cycle_table with the comittee_payments_table.

    let data = await committeecycle.aggregate([
        {//aggrigate work in step by step in {}'s
            //here i am applying condition to the first table 
            $match: {
                'committee_id': committee_id,
                'start_date': { $lte: today },
                'active': true
            }
        },
        {// here i join both table.
            $lookup: {
                from: 'committee_payments',
                localField: '_id',
                foreignField: 'cycle_id',
                as: 'payment_details'
            }
        },
        {//here i open the 2nd table array to do condition work on it
            $unwind: '$payment_details'
        },
        { //here i do condition work on the 2nd table.
            $match: {
                'payment_details.member_id': member_id,
                'payment_details.payment_status': false
            }
        }

    ])

    res.send(data);

});


async function committee_winners() {
    try {

        const today = new Date();
        today.setUTCHours(0, 0, 0, 0);
        //////////////////////////////////////////////////////////////////////////////saraa cycle jis k winner select karnaa ha
        let cycles = await committee_cycles.aggregate([
            {
                $match: { 'end_date': today, 'cycle_winner_id': null, 'active': true }
            },
            {
                $lookup: {
                    from: 'shared_committees',
                    localField: 'committee_id',
                    foreignField: '_id',
                    as: 'committee_detail'
                }
            },
            {
                $unwind: '$committee_detail'
            }
        ])
        ////////////////////////////////////////////////////////////////////////1 by 1 committee k member laow aur aur unaa sort  karoo.
        cycles.map(async (value, index) => {

            let committee_type = value.committee_detail.committee_type;//1:simple  2:bidding  3:spin
            let member_arrange_type = value.committee_detail.members_arrange_type;//1:arrrange by admin  2:arrange by alphabet
            let cycle_id = value._id;
            let committee_id = value.committee_id;
            let enrollment_period = value.committee_detail.enrollment_period;

            let all_members_of_current = [];

            if (member_arrange_type === '1') {
                all_members_of_current = await committee_members.aggregate([
                    {
                        $match: { 'committee_id': value.committee_id, 'got_the_committee': false, active: true }
                    },
                    //saraa member ko turn number sa sort kia .
                    {
                        $sort: { 'turn_number': 1 }
                    }
                ]);
            }
            else {
                all_members_of_current = await committee_members.aggregate([
                    {
                        $match: { 'committee_id': value.committee_id, 'got_the_committee': false, active: true }
                    },
                    {
                        $lookup: {
                            from: 'users',
                            localField: 'user_id',           // memebr table ko user table sa is lia join kia sort by name
                            foreignField: '_id',
                            as: 'user_detail'
                        }
                    },
                    {
                        $unwind: '$user_detail'
                    },
                    {
                        $sort: { 'user_detail.name': 1 }
                    }
                ]);
            }
            ////////////////////////////////////////////////////////////////////////////////////////////////ab inn member sa committee ka owner select karo.
            //jo k array k top par ha. ye simple k lia ha .

            let winner_id;///is ma member id daaloo ga jo k win kia ha ... inteeno if ka result is ma ha.
            if (committee_type === '1') {
                if (all_members_of_current.length > 0) {
                    winner_id = all_members_of_current[0]._id;
                }
                else {
                    console.log('committee has no members left who havent won yet')
                }
            }
            else if (committee_type === '2') {


                let all_bidders = await cycle_biddings
                    .find({ cycle_id: cycle_id })
                    .sort({ amount: -1 });

                if (all_bidders.length === 0) {
                    if (all_members_of_current.length > 0) {
                        winner_id = all_members_of_current[0]._id;
                    }
                    else {
                        console.log("No Member Left who dont get the committee")
                    }
                }
                else {
                    let winner_bidder = all_bidders[0];//{cycle_id,member_id,amount}
                    winner_id = winner_bidder.member_id;
                }

            }
            else if (committee_type === '3') {
                if (all_members_of_current.length === 0) {
                    console.log("all_members_of_current array is empty");
                } else {
                    const randomItem = all_members_of_current[Math.floor(Math.random() * all_members_of_current.length)];
                    winner_id = randomItem._id;
                }
            }

            ///////////////////////////////////////////////////////////////////////  yehaa ma winner save karoo ga.
            if (winner_id) {
                await committee_cycles.updateOne({ 'committee_id': committee_id, '_id': cycle_id }, { $set: { 'cycle_winner_id': winner_id } });
                await committeemember.updateOne({ '_id': winner_id }, { $set: { 'got_the_committee': true } });
                if (enrollment_period) {
                    await sharedCommittee.updateOne({ '_id': committee_id }, { $set: { 'enrollment_period': false } });
                }
            }

        })


    }
    catch (error) {
        console.log(error);
    }
}

app.post('/current-cycle-committee-winner', async (req, res) => {
    const date = new Date(req.body.today);
    let committee_id = new mongoose.Types.ObjectId(req.body.committee_id);
    date.setUTCHours(0, 0, 0, 0); //  Set the time to exactly 00:00:00.000 in UTC
    let data = await committeecycle.aggregate([
        {
            $match: {
                'committee_id': committee_id,
                'end_date': date,
            }
        }
        ,
        {
            $lookup: {
                from: 'committee_members',
                localField: 'cycle_winner_id',
                foreignField: '_id',
                as: 'member'
            }
        }
        ,
        {
            // preserveNullAndEmptyArrays ensures you don't lose the cycle if no winner is found
            $unwind: { path: '$member', preserveNullAndEmptyArrays: true }
        }
        ,
        {
            $lookup: {
                from: 'users',
                localField: 'member.user_id',
                foreignField: '_id',
                as: 'user_detail'
            }
        }
        ,
        {
            $unwind: '$user_detail'
        }

    ])

    res.send(data[0]);

})


app.get('/remaining-members/:id', async (req, res) => {
    const committee_id = new mongoose.Types.ObjectId(req.params.id);

    try {
        const data = await committeemember.aggregate([
            //  Remaining members only            joining the [committee_memebrs] [committee_cycle] [users]
            {
                $match: {
                    committee_id: committee_id,
                    got_the_committee: false,
                    active: true,
                }
            },


            {
                $lookup: {
                    from: 'users',
                    localField: 'user_id',
                    foreignField: '_id',
                    as: 'user_detail'
                }
            }
            ,
            {
                $unwind: '$user_detail'
            }
            ,
            {
                $sort: { 'turn_number': 1 }
            }
        ]);

        res.send(data);
    } catch (err) {
        res.status(500).send(err.message);
    }
});


////////////////////////////////////////////////   join Committee   //////////////////////////////////////////////////

app.get('/committee-of-this-no/:number', async (req, res) => {
    let phoneno = req.params.number;
    let data = await usermodel.aggregate([
        {
            $match: { 'phoneno': phoneno }
        },
        {
            $lookup: {
                from: 'shared_committees',
                localField: '_id',
                foreignField: 'admin_id',
                as: 'committee_detail'
            }
        },
        {
            $unwind: '$committee_detail'
        },
        {
            $match: { 'committee_detail.enrollment_period': true }
        }
    ])

    res.send(data);
})

////////////////////////////////////////////     Notification   ///////////////////////////////////////////////////
app.post('/create-notification', async (req, res) => {
    try {
        let notification_data = req.body;
        const newnotification = new notificationmodel(notification_data);
        await newnotification.save();
        res.send("Request Sent");
    }
    catch (error) {
        console.log(error);
    }
})

app.get('/all-notifications', async (req, res) => {
    try {
        let cookie = req.cookies.phoneno;
        let decode = jwt.verify(cookie, 'shhh');
        let phoneno = decode.phoneno;
        let user = await usermodel.findOne({ 'phoneno': phoneno });
        let data = await notificationmodel.find({ 'receiver_id': user._id });
        res.send(data);
    }
    catch (error) {
        console.log(error);
    }
})
//*********when a user request to join committee***********/
app.post('/reject-request/:id', async (req, res) => {
    try {
        let data = req.body;
        const newnotification = new notificationmodel(data);
        await newnotification.save();
        await notificationmodel.deleteOne({ '_id': req.params.id });
        res.send("rejected");
    }
    catch (error) {
        console.log(error);
    }

})

app.get('/get-notifications/:userId', async (req, res) => {

    try {

        const data = await notificationmodel.find({
            receiver_id: req.params.userId
        }).sort({ createdAt: -1 });

        res.send(data);

    } catch (error) {

        console.log(error);
        res.send(error.toString());
    }
});

app.post('/accept-request/:id', async (req, res) => {
    let data = req.body;
    ///first i check enrollment period is true ..because if admin accept the request late the program not crash.
    let committee_details = await sharedCommittee.findOne({ '_id': data.committee_id });
    if (committee_details.enrollment_period === true) {

        for (let i = 0; i < data.number_of_committee; i++) {
            await sharedCommittee.updateOne(
                { '_id': data.committee_id },
                { $inc: { 'number_of_member': 1 } }
            );//increment member by 1 so i can easily calculate the cycle details.
            committee_details = await sharedCommittee.findOne({ '_id': data.committee_id });//again fetch the updated committee details so i can use them .

            const newmember = new committeemember({
                'committee_id': data.committee_id,
                'user_id': data.user_id,
                'turn_number': committee_details.number_of_member
            });
            let nmember = await newmember.save();//create new member of the committee

            //start_date==sd   deadline_date===dd  days_gap===dg   cyclenumber>>number_of_member in committee==cn  
            let calculated_dates = dates_calculator_function(committee_details.start_date, committee_details.deadline_day, committee_details.days_gap, committee_details.number_of_member);
            const newcycle = new committeecycle({ 'committee_id': data.committee_id, 'cycle_number': committee_details.number_of_member, 'start_date': calculated_dates.start_date, 'end_date': calculated_dates.end_date, 'deadline_date': calculated_dates.deadline_date });
            let ncycle = await newcycle.save();
            //get create payments of all the cycle for new member.

            let array_of_all_cycles = await committee_cycles.find({ 'committee_id': data.committee_id })


            // create payments for NEW MEMBER in ALL cycles
            for (let value of array_of_all_cycles) {
                let exists = await committee_payment.findOne({
                    member_id: nmember._id,
                    cycle_id: value._id
                });

                if (!exists) {
                    let newpayment = new committee_payment({
                        member_id: nmember._id,
                        cycle_id: value._id
                    });
                    await newpayment.save();
                }
            }


            //create payment of all members with the ids of previous members.

            let array_of_already_joined_committee = await committeemember.find({
                committee_id: data.committee_id,   // ✅ IMPORTANT FILTER
                _id: { $ne: nmember._id },
                active: true
            });            //now i will create payment to all already joined memeber of new cycle except that one that i currently saved
            //beacuse i have already created all the payment of his.

            for (let value of array_of_already_joined_committee) {
                let exists = await committee_payment.findOne({
                    member_id: value._id,
                    cycle_id: ncycle._id
                });

                if (!exists) {
                    let newpayment = new committee_payment({
                        member_id: value._id,
                        cycle_id: ncycle._id
                    });
                    await newpayment.save();
                }
            }

        }
        await notificationmodel.deleteOne({ '_id': req.params.id });
        res.send("Member Added");
    }
    else {
        res.send("Enrollment Closed");
    }

})
//*******************   used when handle payment notification     ************************/
app.delete('/clear-payment-notification/:id', async (req, res) => {
    let notification_id = req.params.id;
    await notificationmodel.deleteOne({ '_id': notification_id });
    res.send('Notification Cleared')
})


//*********************************************** */
app.post('/invite-member', async (req, res) => {

})
app.post('/accept-invite', async (req, res) => {

})
//
app.delete('/clear-notification/:id', async (req, res) => {
    try {
        await notificationmodel.deleteOne({ '_id': req.params.id });
        res.send('cleared');
    }
    catch (error) {
        console.log(error);
    }
});

//////////////////////////////////////////    Bidding   //////////////////////////////////////////////
app.get('/get-details-of-committee/:id', async (req, res) => {
    let id = req.params.id;
    let committee_detail = await sharedcommittees.findOne({ '_id': id });
    res.send(committee_detail);
})
app.post('/current-bidding-cycle', async (req, res) => {
    try {

        let obj = req.body;//{committee_id,member_id,amount}
        let date = new Date();
        date.setUTCHours(0, 0, 0, 0);
        let cycle_data = await committee_cycles.findOne({
            'committee_id': obj.committee_id,
            'active': true,
            'cycle_winner': null,
            'start_date': { $lte: date },
            'end_date': { $gt: date }
        })
        if (cycle_data) {
            const newBidding = new cycle_biddings({ 'cycle_id': cycle_data._id, 'member_id': obj.member_id, 'amount': obj.amount });
            await newBidding.save();
            res.send('Bid Successful');
        }
        else {
            res.send("You Cannot Bid Today Try again Tommorow");
        }

    } catch (error) {
        console.log(error);
    }


})
app.get('/current-cycle-winner-bidder-of-committee/:id', async (req, res) => {
    try {
        let id = new mongoose.Types.ObjectId(req.params.id);

        let date = new Date();
        date.setUTCHours(0, 0, 0, 0);

        let cycle_data = await committee_cycles.findOne({
            committee_id: id,
            active: true,
            cycle_winner: null,
            start_date: { $lte: date },
            end_date: { $gt: date }
        });

        if (!cycle_data) {
            return res.status(404).send({ message: "No active cycle found" });
        }

        let all_bidders = await cycle_biddings
            .find({ cycle_id: cycle_data._id })
            .sort({ amount: -1 });

        if (all_bidders.length === 0) {
            return res.status(404).send({ message: "No bidders found" });
        }

        let winner_bidder = all_bidders[0];

        let user = await committee_members.aggregate([
            { $match: { _id: winner_bidder.member_id } },
            {
                $lookup: {
                    from: 'users',
                    localField: 'user_id',
                    foreignField: '_id',
                    as: 'user_detail'
                }
            },
            { $unwind: '$user_detail' }
        ]);

        if (user.length === 0) {
            return res.status(404).send({ message: "User not found" });
        }

        res.send({
            member_id: winner_bidder.member_id,
            name: user[0].user_detail.name,
            amount: winner_bidder.amount
        });

    } catch (error) {
        console.error(error);
        res.status(500).send({ message: "Server Error" });
    }
});


/////////////////////////////////////////     Transfer Admin   //////////////////////////////////
app.post('/get-all-member-comittee', async (req, res) => {
    //this contain all member except the committee admin
    try {
        let { committee_id, admin_id } = req.body;

        const data = await committee_members.aggregate([
            {
                $match: {
                    committee_id: new mongoose.Types.ObjectId(committee_id),
                    user_id: { $ne: new mongoose.Types.ObjectId(admin_id) }
                }
            },
            {
                $group: { _id: "$user_id" }
            },
            {
                $lookup: {
                    from: "users",
                    localField: "_id",
                    foreignField: "_id",
                    as: "user"
                }
            },
            { $unwind: "$user" }
        ]);

        res.send(data);
    }
    catch (error) {
        console.log(error)
    }

});

app.post('/new-committee-admin', async (req, res) => {
    try {
        let { committee_id, old_admin_id, new_admin_id } = req.body;

        // 1. Check committee exists
        let committee = await sharedCommittee.findById(committee_id);
        if (!committee) return res.send("Committee not found");

        // 2. Check old admin matches
        if (committee.admin_id.toString() !== old_admin_id) {
            return res.send("Unauthorized");
        }

        // 3. Prevent same admin
        if (old_admin_id === new_admin_id) {
            return res.send("Already admin");
        }

        // 4. Check new admin is member
        let isMember = await committee_members.findOne({
            committee_id: committee_id,
            user_id: new_admin_id,
            active: true
        });

        if (!isMember) {
            return res.send("New admin must be a member");
        }

        // 5. Update admin
        await sharedCommittee.updateOne(
            { _id: committee_id },
            { $set: { admin_id: new_admin_id } }
        );

        res.send("Admin transferred successfully");

    } catch (error) {
        console.log(error);
        res.status(500).send("Error");
    }
});

app.delete('/delete-committee/:id', async (req, res) => {
    try {
        let committee_id = req.params.id;
        await sharedcommittees.deleteOne({ '_id': committee_id });
        await committee_members.deleteMany({ 'committee_id': committee_id });
        let all_cycle_id = await committee_cycles.find({ 'committee_id': committee_id }, { '_id': 1 })//[{_id:23123},{}]
        all_cycle_id.forEach(async (value, index) => {
            await committee_payment.deleteMany({ 'cycle_id': value._id });
            await cycle_biddings.deleteMany({ 'cycle_id': value._id });
            await committee_cycles.deleteOne({ '_id': value._id });
        })
        res.send('committee_deleted');
    }
    catch (error) {
        console.log(error)
    }

})

app.get('/get-all-members-of-committee/:id', async (req, res) => {
    //this contain all the members including the committee admin
    let committee_id = new mongoose.Types.ObjectId(req.params.id);

    let data = await committee_members.aggregate([
        {
            $match: {
                'committee_id': committee_id,
                'active': true
            }
        }
        ,
        {
            $lookup: {
                from: 'users',
                localField: 'user_id',
                foreignField: '_id',
                as: 'user_detail'
            }
        }
        ,
        {
            $unwind: '$user_detail'
        }
    ])
    res.send(data);

})



app.put('/increment-member-rating', async (req, res) => {
    try {
        const { user_id, member_id } = req.body;

        // Increment only if rating is less than 5
        const updateResult = await committee_members.updateOne(
            { _id: member_id, user_rating: { $lt: 5 } },
            { $inc: { user_rating: 1 } }
        );

        if (updateResult.modifiedCount === 0) {
            return res.send("Rating already at maximum (5)");
        }

        // Recalculate average
        const all_ratings = await committee_members.find(
            { user_id: user_id },
            { user_rating: 1 }
        );

        const count = all_ratings.length;

        const sum = all_ratings.reduce(
            (total, item) => total + item.user_rating,
            0
        );

        let rating_avg = count > 0
            ? Math.round(sum / count)
            : 1;  // minimum 1


        await users.updateOne(
            { _id: user_id },
            { $set: { rating: rating_avg } }
        );

        res.send("Rating incremented");

    } catch (error) {
        res.send(error);
    }
});


app.put('/decrement-member-rating', async (req, res) => {
    try {
        const { user_id, member_id } = req.body;

        // Decrement only if rating is greater than 1
        const updateResult = await committee_members.updateOne(
            { _id: member_id, user_rating: { $gt: 1 } },
            { $inc: { user_rating: -1 } }
        );

        if (updateResult.modifiedCount === 0) {////modifiedCount is the mongodb result.how many documents are modified.
            return res.send("Rating already at minimum (1)");
        }

        // Recalculate average so i can update the actual user value.
        const all_ratings = await committee_members.find(
            { user_id: user_id },
            { user_rating: 1 }
        );

        const count = all_ratings.length;

        const sum = all_ratings.reduce(
            (total, item) => total + item.user_rating,
            0 //initial value
        );

        let rating_avg = count > 0
            ? Math.round(sum / count)
            : 1;

        await users.updateOne(
            { _id: user_id },
            { $set: { rating: rating_avg } }
        );

        res.send("Rating decremented");

    } catch (error) {
        console.log(error);
    }
});



app.get('/all-cycle-till-now-committee/:id', async (req, res) => {
    try {
        let committeeId = req.params.id;

        let data = await committee_cycles.find({
            committee_id: new mongoose.Types.ObjectId(committeeId)
        }).sort({ cycle_number: 1 });

        res.send(data);
    } catch (error) {
        console.log(error);
        res.send([]);
    }
});

app.get('/get-payment-of-cycle/:id', async (req, res) => {
    let cycle_id = req.params.id;
    let data = await committee_payment.aggregate([
        {
            $match: {
                'cycle_id': new mongoose.Types.ObjectId(cycle_id)
            }
        }
        ,
        {
            $lookup: {
                from: 'committee_members',
                localField: 'member_id',
                foreignField: '_id',
                as: 'member_detail'
            }
        }
        ,
        {
            $unwind: '$member_detail'
        }
        ,
        {
            $lookup: {
                from: 'users',
                localField: 'member_detail.user_id',
                foreignField: '_id',
                as: 'user_detail'
            }
        }
        ,
        {
            $unwind: '$user_detail'
        }
    ])

    res.send(data);
})

let payment_notification = async (member_id, cycle_id, committee_detail, payment_type) => {
    let user_detail;
    let temp = await committee_members.aggregate([
        {
            $match: { '_id': new mongoose.Types.ObjectId(member_id) }
        },
        {
            $lookup: {
                from: 'users',
                localField: 'user_id',
                foreignField: '_id',
                as: 'user_detail'
            }
        },
        {
            $unwind: '$user_detail'
        }
    ]);
    user_detail = temp[0].user_detail;


    let notification_obj = {
        'receiver_id': committee_detail.admin_id,
        'committee_id': committee_detail._id,
        'user': user_detail,
        'committee_detail': { ...committee_detail },
        'member_id': member_id,
        'cycle_id': cycle_id,
        'payment_type': payment_type,
        'notification_type': 4
    }
    return notification_obj
}

app.post('/payment-handle', upload.single('payment_img'), async (req, res) => {
    try {
        // 1. Destructure the text fields
        let { payment_type, cycle_id, member_id, committee_detail } = req.body;
        // 2. Parse the object back from the string
        let committee = JSON.parse(committee_detail);
        let notification_obj = await payment_notification(member_id, cycle_id, committee, payment_type);
        let newnotification = new notificationmodel(notification_obj);
        await newnotification.save();
        console.log(req.body);
        console.log(req.file);

        if (payment_type === 'cash') {
            await committee_payment.updateOne(
                { cycle_id, member_id },
                { $set: { 'payment_type': payment_type, 'payment_status': true } });
        }
        else {
            let payment_img = req.file.filename;
            await committee_payment.updateOne(
                { cycle_id, member_id },
                { $set: { 'payment_type': payment_type, 'payment_status': true, payment_img } });
        }
        res.send("Approvel Send to committee Admin");
    }
    catch (error) {
        console.log(error)
    }

})

app.put('/approve-payment', async (req, res) => {
    try {
        let obj = req.body;

        await committee_payment.updateOne(
            {
                cycle_id: obj.cycle_id,
                member_id: obj.member_id
            },
            {
                $set: {
                    payment_status: true,
                    approval: true
                }
            }
        );

        let notif = new notificationmodel({
            receiver_id: obj.user_id,
            committee_id: obj.committee_id,
            member_id: obj.member_id,
            cycle_id: obj.cycle_id,
            message: "Your payment has been approved by admin",
            notification_type: 5
        });

        await notif.save();

        res.send("Approved");
    } catch (error) {
        console.log(error);
        res.send("Error");
    }
});

app.put('/reject-payment', async (req, res) => {
    let obj = req.body;//{ cycle_id, member_id, user_id,committee_id, message }
    await committee_payment.updateOne({ cycle_id: obj.cycle_id, member_id: obj.member_id },
        { $set: { payment_type: 'Not Paid yet', payment_img: null, payment_status: false, approval: false } });
    let newnotification = notificationmodel({
        receiver_id: obj.user_id,
        committee_id: obj.committee_id,
        member_id: obj.member_id,
        cycle_id: obj.cycle_id,
        message: obj.message,
        notification_type: 5
    });
    await newnotification.save();
    res.send('Payment Reject Successfully');
})

app.put('/admin-pay-member-payment', async (req, res) => {
    let obj = req.body //{member_id,cycle_id}
    await committee_payment.updateOne(
        { member_id: obj.member_id, cycle_id: obj.cycle_id },
        {
            $set: {
                payment_type: 'cash',
                payment_status: true,
                approval: true,
            }
        }
    )
    res.send("You have Successfull paid payment of a member.")
})
//////////////////////////////////////////////////
app.post('/exit-committee', async (req, res) => {
    try {
        const data = req.body;

        // 1. Extract and Clean Variables
        const committee_id = data.committee_id;
        const user_id = data.user_id;
        const member_id = data._id;

        // Convert to Number to ensure "1" === 1 doesn't fail
        const committee_leaving_type = Number(data.committee_details?.committee_leaving_type);
        const member_got_committee = data.got_the_committee;

        // 2. Fetch required details 
        const committee_admin_details = await usermodel.findOne({ _id: data.committee_details.admin_id });
        const committee_exitter_details = await usermodel.findOne({ _id: user_id });

        const number_of_cycle_paid = await committee_payment.countDocuments({
            member_id: member_id,
            approval: true
        });

        const return_amount = number_of_cycle_paid * Number(data.committee_details.amount);

        // 3. Logic for Committee Leaving Type 1
        if (committee_leaving_type === 1) {
            if (member_got_committee) {
                if (return_amount > 0) {
                    const userNotif = new notificationmodel({
                        receiver_id: user_id,
                        committee_id: committee_id,
                        notification_type: 6,
                        committee_detail: data.committee_details,
                        member_id: member_id,
                        amount: return_amount,
                        user: committee_admin_details,
                        message: "admin will divide this amount to members who dont got the kitty"
                    });
                    await userNotif.save();

                    const adminNotif = new notificationmodel({
                        receiver_id: data.committee_details.admin_id,
                        committee_id: committee_id,
                        notification_type: 7,
                        committee_detail: data.committee_details,
                        member_id: member_id,
                        user: committee_exitter_details
                    });
                    await adminNotif.save();

                    const newRefund = new committee_refund({
                        user_id: user_id,
                        committee_id: committee_id,
                        amount: return_amount,
                    });
                    await newRefund.save();
                }
            } else {
                // If member DID NOT get the committee
                const winners = await committee_members.find({
                    committee_id: committee_id,
                    got_the_committee: true
                });

                // Use Promise.all for better performance in loops
                await Promise.all(winners.map(item => {
                    const winNotif = new notificationmodel({
                        receiver_id: item.user_id,
                        committee_id: item.committee_id,
                        notification_type: 8,
                        committee_detail: data.committee_details,
                        member_id: item._id,
                        amount: data.committee_details.amount,
                        user: committee_admin_details,
                        message: "admin will give back this amount to the member who exits the committee"
                    });
                    return winNotif.save();
                }));

                const adminNotif = new notificationmodel({
                    receiver_id: data.committee_details.admin_id,
                    committee_id: committee_id,
                    notification_type: 7,
                    committee_detail: data.committee_details,
                    member_id: member_id,
                    user: committee_exitter_details
                });
                await adminNotif.save();
            }
        }

        // 4. Logic for Committee Leaving Type 2
        else if (committee_leaving_type === 2) {
            if (member_got_committee) {
                if (return_amount > 0) {
                    const userNotif = new notificationmodel({
                        receiver_id: user_id,
                        committee_id: committee_id,
                        notification_type: 6,
                        committee_detail: data.committee_details,
                        member_id: member_id,
                        amount: return_amount,
                        message: "admin will divide this amount to every member",
                        user: committee_admin_details
                    });
                    await userNotif.save();

                    const adminNotif = new notificationmodel({
                        receiver_id: data.committee_details.admin_id,
                        committee_id: committee_id,
                        notification_type: 7,
                        committee_detail: data.committee_details,
                        member_id: member_id,
                        user: committee_exitter_details
                    });
                    await adminNotif.save();

                    const newRefund = new committee_refund({
                        user_id: user_id,
                        committee_id: committee_id,
                        amount: return_amount,
                    });
                    await newRefund.save();
                }
            } else {
                const adminNotif = new notificationmodel({
                    receiver_id: data.committee_details.admin_id,
                    committee_id: committee_id,
                    notification_type: 7,
                    committee_detail: data.committee_details,
                    member_id: member_id,
                });
                await adminNotif.save();

                const calcAmount = Math.round(data.committee_details.amount) / (data.committee_details.number_of_member - 1);
                const temp_amount = data.committee_details.amount + calcAmount;
                await sharedcommittees.updateOne({ committee_id: committee_id }, { $set: { amount: temp_amount } });
            }
        }

        // 5. Cleanup and Status Updates
        await committee_members.updateOne(
            { _id: member_id, committee_id: committee_id },
            { $set: { active: false } }
        );

        await sharedCommittee.updateOne(
            { _id: committee_id },
            { $inc: { number_of_member: -1 } }
        );

        await committee_payment.deleteMany({
            member_id: member_id,
            payment_status: false
        });

        // FIX: Find the cycle first and check if it exists before using its ID
        const updated_cycle = await committee_cycles.findOneAndUpdate(
            { committee_id: committee_id },
            { $set: { active: false } },
            { sort: { cycle_number: -1 }, new: true }
        );

        if (updated_cycle) {
            await committee_payment.deleteMany({
                cycle_id: updated_cycle._id,
                payment_status: false
            });
        }

        res.status(200).send("Exit Successful");

    } catch (error) {
        console.error("Exit Committee Error:", error);
        res.status(500).send("An error occurred during exit process.");
    }
});

app.get('/get-all-refunds/:id', async (req, res) => {
    let committee_id = new mongoose.Types.ObjectId(req.params.id);
    let data = await committee_refund.find({ committee_id });
    res.send(data);
})

app.put('/pay-refund', upload.single('payment_img'), async (req, res) => {
    let obj = req.body;
    //{committee_id
    // ,user_id {who pay the return amount}
    // ,payment_type
    // ,message
    // ,committee_admin_id,
    // amount}
    console.log(obj);
    let singlefile = req.file;
    if (singlefile) {
        await committee_refund.updateOne({ 'committee_id': obj.committee_id, 'user_id': obj.user_id }, {
            $set: {
                payment_type: obj.payment_type,
                payment_status: true,
                payment_img: singlefile.filename
            }
        })

    }
    else {
        await committee_refund.updateOne({ 'committee_id': obj.committee_id, 'user_id': obj.user_id }, {
            $set: {
                payment_type: obj.payment_type,
                payment_status: true
            }
        })
    }

    let adminnotification = await notificationmodel({//user_id  committee_id  amount message
        receiver_id: obj.committee_detail.admin_id,
        committee_id: obj.committee_details._id,
        member_id: obj.user_id,
        amount: obj.amount,
        message: obj.message,
        notification_type: 9
    })
    adminnotification.save();
    res.send("Approval Sent to Admin.");
})

app.put('/reject-refund', async (req, res) => {
    let obj = req.body;//{committee_id,user_id,message} message for reason of rejection
    console.log(obj);
    await committee_refund.updateOne({ 'committee_id': obj.committee_id, 'user_id': obj.user_id }, {
        $set: {
            payment_type: 'Not Paid yet',
            payment_status: false
        }
    })

    let newnotif = new notificationmodel({
        receiver_id: obj.user_id,
        member_id: obj.user_id,
        committee_id: obj.committee_id,
        message: obj.message,
        notification_type: 5
    })
    await newnotif.save();
})