import { CSV, Record, RecordAction } from './CSV';
import { firstValueFrom } from 'rxjs';
import {Config} from "../config";

const providerCount = Config.getLink.length;

export class Renderer {
	constructor(
		private readonly csv: CSV,
	) {}

	async index() {
		return `<!DOCTYPE html>
<head>
	<link rel="stylesheet" href="styles.css">
</head>
<body>
	<script type="text/javascript" src="jquery-3.7.1.min.js"></script>
	<script type="text/javascript" src="app.js"></script>
	${await this.fileTable()}
</body>`
	}

	private async fileTable(){
		const data: Record[] = await firstValueFrom(this.csv.data$);
		return `<table>
	<tr>
		<th class="no">#</th>
		<th class="name" colspan="${providerCount}">Name</th>
		<th class="duration">[YT] Time</th>
		<th colspan="2">Status</th>
	</tr>
	${data.map((row, i) => this.fileRow(i, row)).join('')}
</table>`;
	}

	private fileRow(row: number, [ fileName, time, status ]: [string, string, string?]) {
		const statusClass = this.getStatusClass(status);
		const buttons = statusClass
			? [
				this.button(row, RecordAction.Reset, '↺', 'reset'),
			]
			: [
				this.button(row, RecordAction.Done, '✔', 'success'),
				this.button(row, RecordAction.Failed, '❌', 'error'),
			]
		const trClass = statusClass ? ` class="${statusClass}"` : '';
		return `<tr${trClass} data-no="${row}">
	<td class="no">${row}</td>
	${Config.getLink.map(getLink => `<td class="name"><a href="${getLink(fileName)}">${fileName}</a></td>`).join('\n\t')}
	<td class="duration">${time}</td>
	<td class="status">${status ?? ''}</td>
	<td class="actions"><span class="actions">${buttons.join('')}</span></td>
</tr>
`;
	}

	private getStatusClass(status?: string) {
		if (!status) {
			return undefined;
		}
		return (status == '✔')
			? 'done'
			: status.match(/^!/)
				? 'failed'
				: 'unknown';
	}

	private button(row: number, action: RecordAction, text: string, className: string){
		return `<a href="?row=${row}&action=${action}" class="btn ${className}" data-type="action">${text}</a>`
	}
}
