import { Renderer } from './src/renderer';
import { isNumber, isString } from 'lodash';
import { Server, ServerConfig } from './src/app';
import * as fs from 'fs';
import { CSV } from './src/CSV';

const port = 3000;
let start = true;

function help() {
	start = false;
	console.info(`
server.ts <source.tsv> [-p port]
	-p	port (${port} by default)
`);
}

const config: ServerConfig = {
	port
};

const runtime: {
	src?: string
} = {};

for (let i = 2; i < process.argv.length; i++) {
	switch (process.argv[i]) {
		case '-p':
			i++;
			let port = Number.parseInt(process.argv[i]);
			if (!isNumber(port)) {
				throw new Error(`Invalid port: ${process.argv[i]}`);
			}
			config.port = port;
			break;
		case '-?':
		case '-h':
			help();
			break;
		default:
			if (fs.existsSync(process.argv[i])) {
				runtime.src = process.argv[i];
			}
	}
}

if (isString(runtime.src) && start) {
	const csv = new CSV(runtime.src);
	const renderer = new Renderer(csv);
	const server = new Server(config, csv, renderer);
	server.run();
} else {
	help();
}
