import { ArtistModel } from '../model/Artist.js';
import { CustomerModel } from '../model/Customer.js';
import BookingModel from '../model/Booking.js';
import PaymentModel from '../model/paymentModel.js';

export const getSummaryCounts = async (req, res) => {
    try {
        const [totalArtists, totalCustomers, totalBookings] = await Promise.all([
            ArtistModel.countDocuments(),
            CustomerModel.countDocuments(),
            BookingModel.countDocuments()
        ]);
        // If you have a User model, add its count here. Otherwise, sum artists and customers.
        const totalUsers = totalArtists + totalCustomers;

        res.json({
            totalUsers,
            totalArtists,
            totalCustomers,
            totalBookings
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch summary counts', details: err.message });
    }
};

// Monthly transaction counts for the last 12 months
export const getMonthlyTransactionCounts = async (req, res) => {
    try {
        const now = new Date();
        const months = [];
        for (let i = 11; i >= 0; i--) {
            const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
            months.push({ year: d.getFullYear(), month: d.getMonth() + 1 });
        }

        const pipeline = [
            {
                $match: {
                    createdAt: {
                        $gte: new Date(now.getFullYear(), now.getMonth() - 11, 1)
                    }
                }
            },
            {
                $group: {
                    _id: { year: { $year: "$createdAt" }, month: { $month: "$createdAt" } },
                    count: { $sum: 1 }
                }
            }
        ];

        const results = await PaymentModel.aggregate(pipeline);

        // Map results to months array
        const data = months.map(({ year, month }) => {
            const found = results.find(r => r._id.year === year && r._id.month === month);
            return {
                year,
                month,
                count: found ? found.count : 0
            };
        });

        res.json({ data });
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch monthly transaction counts', details: err.message });
    }
};

// Weekly transaction counts for the last 8 weeks
export const getWeeklyTransactionCounts = async (req, res) => {
    try {
        const now = new Date();
        const start = new Date(now);
        start.setDate(now.getDate() - 7 * 7); // 8 weeks ago

        const pipeline = [
            {
                $match: {
                    createdAt: { $gte: start }
                }
            },
            {
                $addFields: {
                    week: { $isoWeek: "$createdAt" },
                    year: { $isoWeekYear: "$createdAt" }
                }
            },
            {
                $group: {
                    _id: { year: "$year", week: "$week" },
                    count: { $sum: 1 }
                }
            },
            { $sort: { "_id.year": 1, "_id.week": 1 } }
        ];

        const results = await PaymentModel.aggregate(pipeline);

        res.json({ data: results });
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch weekly transaction counts', details: err.message });
    }
};

export const getLatestCustomers = async (req, res) => {
    try {
        const customers = await CustomerModel.find({}, { name: 1, profilePictureUrl: 1, createdAt: 1 })
            .sort({ createdAt: -1 })
            .limit(10);
        res.json({ customers });
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch latest customers', details: err.message });
    }
};

export const getHighestBookedArtists = async (req, res) => {
    try {
        const pipeline = [
            { $group: { _id: "$artistID", bookingCount: { $sum: 1 } } },
            { $sort: { bookingCount: -1 } },
            { $limit: 10 },
            {
                $lookup: {
                    from: "artists",
                    localField: "_id",
                    foreignField: "_id",
                    as: "artist"
                }
            },
            { $unwind: "$artist" },
            {
                $project: {
                    _id: 0,
                    artistId: "$artist._id",
                    name: "$artist.name",
                    profilePictureUrl: "$artist.profilePictureUrl",
                    bookingCount: 1
                }
            }
        ];
        const artists = await BookingModel.aggregate(pipeline);
        res.json({ artists });
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch highest booked artists', details: err.message });
    }
};