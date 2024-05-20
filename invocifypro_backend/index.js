const express = require('express')
const cors = require('cors')
const api = require("./api")

const app = express()
const port = 3000

app.use(cors())
app.use(express.json());

app.use('/shoplogos', express.static('uploads/shoplogos'));

app.use('/', api);

app.listen(port, () => console.log(`Example app listening on port ${port}!`))

const ngrok = require('@ngrok/ngrok');
// Get your endpoint online
ngrok.forward({ addr: 3000, domain: "obliging-jointly-bengal.ngrok-free.app", authtoken_from_env: true })
    .then(listener => console.log(`Ingress established at: ${listener.url()}`));