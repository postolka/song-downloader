import express, { Request, Response } from 'express';
import { Renderer } from './renderer';
import { CSV, getChangeRequest } from './CSV';

export interface ServerConfig {
	port: number;
}

export class Server {
	private running = false;

	constructor(
		private readonly config: ServerConfig,
		private readonly csv: CSV,
		private readonly renderer: Renderer,
	) {
	}

	run() {
		if (this.running) {
			console.warn('Already running');
			return;
		}

		this.running = true;
		const app = express();

		app.use(express.static('public'))

		app.get('/', async (req: Request, res: Response) => {
			const changeRequest = getChangeRequest(req.query);
			if (changeRequest) {
				await this.csv.update(changeRequest.row, changeRequest.action);
			}

			res.set('Content-Type', 'text/html');
			this.renderer.index().then(html => res.send(Buffer.from(html)));
		});

		app.listen(this.config.port, () => {
			console.log(`App listening at http://localhost:${this.config.port}`);
		});
	}
}
