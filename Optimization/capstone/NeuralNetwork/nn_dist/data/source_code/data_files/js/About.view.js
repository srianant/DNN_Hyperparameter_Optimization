sap.ui.jsview("view.About", {

	getControllerName : function() {
		return "view.About";
	},

	createContent : function(oController) {

		return new sap.m.Page( {
			title: "{i18n>about}",
			showNavButton: true,
			navButtonTap: [oController.onNavButtonTap],
			content: [ 
				new sap.ui.core.HTML({content:
					"<p><strong>About Live 2</strong></p>"+
					"<p>This app is part of the SAP enablement offering <i>SAP HANA SPS7 Bootcamp by HANA Academy</i> which is a free course presented by the SAP HANA Academy.</p>"+ 
					"<p>During this 3-day bootcamp, we help you get started with SAP HANA SPS7 by walking through a step-by-step project to build a mobile application with predictive analytics and real-time data feeds using the native features available within the SAP HANA development platform.</p>"+
					"<p>Whether you are new to SAP HANA, or just looking to expand your knowledge, this is a great opportunity to gain hands-on experience with SAP HANA.</p>"+
					"<p><strong>What is the scenario?</strong></p>"+
					"<p>The app allows members of a fictional SAP HANA on-line social network to see suggestions for potential new contacts based on advanced link prediction algorithms executed natively in SAP HANA.</p>"+
					'<p>The app is a native SAP HANA application built using the SAP HANA platform - including SAP HANA extended application services (XS), OData, and OpenUI5. It can easily be deployed as a native mobile app (iOS, Android...) via <a href="http://cordova.apache.org/" target="_system">Cordova</a>.</p>'+
					"<p><strong>What is Link Prediction?</strong></p>"+
					"<p>Given a snapshot of a social network, is it possible to predict which new interactions among its members are likely to occur in the near future? This is known as the 'link prediction' problem and a common task in social network analysis. This is most usually achieved through detailed analysis of the <i>proximity</i> of nodes in the network.<p>"+
					"<p>The link prediction algorithm delivered with the SAP HANA predictive analysis library provides four methods to compute the <i>proximity</i> of any two nodes in order to predict new interactions. The four methods are:</p>"+
					"<ol><li>Common Neighbors</li><li>Jaccard's Coefficient</li><li>Adamic/Adar</li><li>Katz</li></ol>"+
					"<p><strong>Does the SAP HANA Academy have any more enablement?</strong></p>"+
					'<p>Yes! Check out the hundreds of videos and enablement topics at <a href="http://academy.saphana.com" target="_system">academy.saphana.com</a></p>'+
					"<p><strong>Contact us</strong></p>"+
					'<p>Email: <a href="mailto:HanaAcademy@sap.com">HanaAcademy@sap.com</a><br>Visit us at: <a href="http://academy.saphana.com" target="_system">academy.saphana.com</a></p>'
				})
			]
		});

	}

});
