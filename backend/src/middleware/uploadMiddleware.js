const multer =
require("multer");

const path =
require("path");

const storage =
multer.diskStorage({

    filename:
        function (
            req,
            file,
            cb
        ) {

        cb(

            null,

            Date.now() +
                path.extname(
                    file.originalname
                )
        );
    },
});

const fileFilter =
(req, file, cb) => {

    console.log(
        "FILE NAME:",
        file.originalname
    );

    console.log(
        "FILE MIME TYPE:",
        file.mimetype
    );

    const allowedExtensions = [

        // IMAGES
        ".jpg",
        ".jpeg",
        ".png",
        ".webp",
        ".heic",
        ".heif",

        // VIDEOS
        ".mp4",
        ".mov",
        ".3gp",
    ];

    const extension =
        path.extname(

            file.originalname
        ).toLowerCase();

    console.log(
        "FILE EXTENSION:",
        extension
    );

    if (
        allowedExtensions.includes(
            extension
        )
    ) {

        cb(null, true);

    } else {

        cb(

            new Error(
                `Unsupported file type: ${extension}`
            ),

            false
        );
    }
};
const upload = multer({

    storage,

    limits: {

        fileSize:
            1024 *
            1024 *
            50,
    },

    fileFilter,
});

module.exports =
    upload;