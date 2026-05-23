const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const compression = require("compression");
const morgan = require("morgan");

const userRoutes = require(
    "./routes/userRoutes"
);

const authRoutes = require(
    "./routes/authRoutes"
);

const postRoutes =
require("./routes/postRoutes");

const notificationRoutes =
require(
    "./routes/notificationRoutes"
);

const app = express();

app.use(express.json());

app.use(cors());

app.use(helmet());

app.use(compression());

app.use(morgan("dev"));

app.use(
    "/api/auth",
    authRoutes
);
// ROUTES
app.use(
    "/api/users",
    userRoutes
);
app.use(
    "/api/posts",
    postRoutes
);

app.use(
    "/api/notifications",
    notificationRoutes
);

// TEST ROUTE
app.get("/", (req, res) => {

    res.json({
        success: true,
        message:
            "AddaLink Backend Running 🚀",
    });
});

module.exports = app;