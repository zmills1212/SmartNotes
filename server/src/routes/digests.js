const express = require('express');
const { getDigests, generateDigest } = require('../controllers/digestsController');
const { authenticate } = require('../middleware/auth');
const router = express.Router();
router.use(authenticate);
router.get('/', getDigests);
router.post('/generate', generateDigest);
module.exports = router;
