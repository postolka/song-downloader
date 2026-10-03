import fs from 'fs';
import { parse, stringify } from 'csv';
import { firstValueFrom, ReplaySubject } from 'rxjs';
import { csvOptions } from './csv-options';
import { Request } from 'express';
import { isString } from 'lodash';

export type Record = [string, string, string?];

export enum RecordAction {
	Done = 'd',
	Failed = 'f',
	Reset = 'r',
}

export interface ChangeRequest {
	row: number,
	action: RecordAction
}

export function getChangeRequest(query: Request['query']): ChangeRequest | undefined {
	if (!(('row' in query) && ('action' in query)))
		return undefined;

	const rowString = query['row'];
	const actionString = query['action'];

	return (isString(rowString) && isString(actionString) && rowString.match(/\d+/) && ([
		RecordAction.Done,
		RecordAction.Failed,
		RecordAction.Reset,
	] as string[]).includes(actionString))
		? {
			row: Number.parseInt(rowString),
			action: actionString as RecordAction,
		}
		: undefined;
}

export class CSV {
	public readonly data$ = new ReplaySubject<Record[]>(1);

	constructor(
		private readonly src: string,
	) {
		const rows: Record[] = [];
		fs.createReadStream(this.src)
			.pipe(parse({
				...csvOptions,
				relax_column_count: true,
			}))
			.on('data', (row) => {
				rows.push(row);
			})
			.on('end', () => {
				this.data$.next(rows);
			})
			.on('error', err => {
				this.data$.error(err);
			});
	}

	async update(row: number, action: RecordAction) {
		const rows = await firstValueFrom(this.data$);
		if (row >= rows.length) {
			throw new Error(`Invalid row: ${rows} / ${rows.length}`);
		}
		const [name, time] = rows[row];
		const rowData = [name, time];
		const rowStatus = this.actionToStatus(action);
		if (rowStatus) {
			rowData.push(rowStatus);
		}
		rows[row] = rowData as Record;

		this.data$.next(rows);

		const stringifier = stringify({
			...csvOptions,
		});

		stringifier.pipe(fs.createWriteStream(this.src));

		for (const row of rows) {
			stringifier.write(row);
		}

		stringifier.end();
		console.debug(`[${action}] #${row} done`);
	}

	private actionToStatus(action: RecordAction): string | undefined {
		switch (action) {
			case RecordAction.Failed:
				return '!!';
			case RecordAction.Done:
				return '✔';
			case RecordAction.Reset:
				return undefined;
		}
		return undefined;
	}
}
