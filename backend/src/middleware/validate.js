'use strict';

const { validationResult } = require('express-validator');

/**
 * Middleware that reads express-validator results and, if errors are found,
 * immediately returns a 400 response with the first validation message.
 *
 * Usage:
 *   router.post('/route', [...validators], validate, controller);
 */
function validate(req, res, next) {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const first = errors.array()[0];
    return res.status(400).json({
      success: false,
      message: first.msg,
      field: first.path ?? first.param, // express-validator v7 uses 'path'
    });
  }

  return next();
}

module.exports = { validate };
