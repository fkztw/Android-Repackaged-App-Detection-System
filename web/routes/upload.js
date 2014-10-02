var express = require('express');
var router = express.Router();

//for file upload
var formidable = require('formidable');
var fs = require('fs');
var path = require('path');

/* GET upload page. */
router.get('/', function(req, res) {
  res.render('upload.jade');
});

/* POST upload BEGIN */
router.post('/', function(req, res) {
    var form = new formidable.IncomingForm();
    getFilename(form, req, res);
});

function getFilename(form, req, res) {
    form.parse(req, function(err, fields, files) {
        if (err) return hadError(err, res);

        // `file` is the name of the <input> field of type `file`
        var old_path = files.file.path,
            file_size = files.file.size,
            file_ext = files.file.name.split('.').pop(),
            index = old_path.lastIndexOf('/') + 1,
            file_name = old_path.substr(index),
            new_path = path.join(process.env.PWD, '/uploads/', file_name + '.' + file_ext);
            //new_path = path.join(process.env.PWD, '/uploads/', files.file.name);

        storeFile(old_path, new_path, res);
    });
}

function storeFile(old_path, new_path, res) {
    fs.readFile(old_path, function(err, data) {
        fs.writeFile(new_path, data, function(err) {
            fs.unlink(old_path, function(err) {
                if (err) return hadError(err, res)

                console.log(old_path + ' uploaded.')
                res.status(200);
                res.end('upload succefully');
            });
        });
    });
}

function hadError(err, res) {
    console.error(err);
    res.status(500);
    res.end('Server Error');
}
/* POST upload END */

module.exports = router;
