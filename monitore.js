function getOrCreateCategory(categoryName) {
	let category = document.getElementById('cat-' + categoryName);
	if(!category) {
		category = document.createElement('details');
		category.id = 'cat-' + categoryName;
		category.setAttribute('open', 'true');

		document.getElementById('status-results').appendChild(category);

		// Spoiler Title
		const summary = document.createElement('summary');
		summary.innerText = categoryName;

		category.appendChild(summary);
	}

	return category;
}

function getOrCreateService(category, serviceName) {
	let service = document.getElementById('service-' + serviceName);
	if(!service) {
		service = document.createElement('div');
		service.id = 'service-' + category + '-'  + serviceName;
		category.appendChild(service);

		// Status
		const status = document.createElement('span');
		status.innerText = '▇ ';
		service.appendChild(status);

		// Name/URL
		const name = document.createElement('span');
		name.innerText = serviceName;

		service.appendChild(name);
	}

	return service;
}

async function checkWebsitesStatus() {
	const serviceList = await (await fetch('status.json')).json();

	for(const categoryName in serviceList) {
		const category = getOrCreateCategory(categoryName);

		for(const serviceName in serviceList[categoryName]) {
			const service = getOrCreateService(category, serviceName);

			service.className = 'service-' + serviceList[categoryName][serviceName];
		}
	}
}

window.addEventListener('load', checkWebsitesStatus);