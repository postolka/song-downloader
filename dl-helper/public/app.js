const selectActionButton = 'a[data-type=action]';

function makeDynamic($a) {
	const href = $a.attr('href');
	const urlParams = new URLSearchParams(href);

	if (urlParams.has('row')) {
		const row = urlParams.get('row');
		$a.on('click', e => {
			e.preventDefault();

			$.get(href, (html) => {
				const selectRow = `tr[data-no=${row}]`;
				const newRow = $(html).find(selectRow);
				makeDynamic(newRow.find(selectActionButton));

				$(selectRow).replaceWith(newRow);

				console.debug(`Row #${row} updated`);
			});
			// console.debug('loading:', urlParams);
		});
	}
}

$.when( $.ready ).then(() => {
	$(selectActionButton).each(function () {
		makeDynamic($(this));
	});
});

