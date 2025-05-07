import mongoose from 'mongoose';
import Works from '../model/works.js';

// Helper function to validate ObjectId
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

// Add a new work
export const addWork = async (req, res) => {
    const { title, description, service } = req.body;
    const artistId = req.params.artistId;

    if (!isValidObjectId(artistId)) {
        return res.status(400).json({ error: "Invalid Artist ID" });
    }

    if (!req.file) {
        return res.status(400).json({ error: "Image is required" });
    }

    try {
        const imageUrl = `http://10.0.2.2:8000/uploads/${req.file.filename}`;
        
        const work = new Works({
            title,
            description,
            service,
            imageUrl,
            artistId
        });

        await work.save();
        return res.status(201).json({ 
            message: 'Work added successfully',
            work 
        });
    } catch (err) {
        console.error('Error adding work:', err);
        return res.status(500).json({ error: err.message });
    }
};

// Update a work
export const updateWork = async (req, res) => {
    const { workId } = req.params;
    const { title, description, service } = req.body;

    if (!isValidObjectId(workId)) {
        return res.status(400).json({ error: "Invalid Work ID" });
    }

    try {
        const updateData = {
            title,
            description,
            service
        };

        if (req.file) {
            updateData.imageUrl = `http://10.0.2.2:8000/uploads/${req.file.filename}`;
        }

        const updatedWork = await Works.findByIdAndUpdate(
            workId,
            updateData,
            { new: true }
        );

        if (!updatedWork) {
            return res.status(404).json({ error: 'Work not found' });
        }

        return res.status(200).json({
            message: 'Work updated successfully',
            work: updatedWork
        });
    } catch (err) {
        console.error('Error updating work:', err);
        return res.status(500).json({ error: err.message });
    }
};

// Delete a work
export const deleteWork = async (req, res) => {
    const { workId } = req.params;

    if (!isValidObjectId(workId)) {
        return res.status(400).json({ error: "Invalid Work ID" });
    }

    try {
        const deletedWork = await Works.findByIdAndDelete(workId);

        if (!deletedWork) {
            return res.status(404).json({ error: 'Work not found' });
        }

        return res.status(200).json({
            message: 'Work deleted successfully'
        });
    } catch (err) {
        console.error('Error deleting work:', err);
        return res.status(500).json({ error: err.message });
    }
};

// Get all works by artist ID
export const getWorksByArtist = async (req, res) => {
    const { artistId } = req.params;

    if (!isValidObjectId(artistId)) {
        return res.status(400).json({ error: "Invalid Artist ID" });
    }

    try {
        const works = await Works.find({ artistId });
        return res.status(200).json({ works });
    } catch (err) {
        console.error('Error fetching works:', err);
        return res.status(500).json({ error: err.message });
    }
};

// Get a single work by ID
export const getWorkById = async (req, res) => {
    const { workId } = req.params;

    if (!isValidObjectId(workId)) {
        return res.status(400).json({ error: "Invalid Work ID" });
    }

    try {
        const work = await Works.findById(workId);

        if (!work) {
            return res.status(404).json({ error: 'Work not found' });
        }

        return res.status(200).json({ work });
    } catch (err) {
        console.error('Error fetching work:', err);
        return res.status(500).json({ error: err.message });
    }
};
