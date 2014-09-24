*** This is the memo for project work ***

1.	The download link of the source package of "googleplaycrawler".
	https://github.com/Akdeniz/google-play-crawler

2.	The detail usages of "googleplaycrawler" are also on the site.
	https://github.com/Akdeniz/google-play-crawler

3.	The "crawler.conf" is the configuration which includes the simluated device ID and account information.
	
4.	The "categories.conf" is the configuration which includes the categories of apps you want to download at one batch shot.
	Note that the name of each category is fixed. 

5.	About the common usage of "googleplaycrawler":
	a.	Showing the details.
		java -jar googleplay.jar -h
	
	b.	Listing the apps of certain category.
		(e.g. Game)
		java -jar googleplay.jar -f crawler.conf list GAME -s apps_topselling_free -n 100
		
		(-s indicates the subcategory of each specified main category.
			"apps_topselling_free" indicates the top free apps)
		(-n indicates the number of apps you want to list at one shot.
			Note that the max number is limited to 100.)

	c.	Listing the apps of cartain category from the specified offset.
		(e.g. From top 101 to 200) 
		java -jar googleplay.jar -f crawler.conf list GAME -s apps_topselling_free -o 100 -n 100	
        the maximum of -o option can only be 4 for each category. You can't get the apps informations more than 500. The crawler return nothing when -o is set more than 400.

		(-o indicates the offset you want to begin with using the number specified in the "-n" parameter as
			range unit.)

	d.	Downloading certain app.
		(e.g. com.xxx.yyy)
		java -jar googleplay.jar -f crawler.conf download com.xxx.yyy

6.	How to use this prototype?
	./AutoCrawler.pl
	
	Note that this prototype is only able to list and download the top 100 apps of the specified category.
	You can easily extend this prototype to download more apps. 
	But due to the restriction set by GooglePlay (maybe the limitation of this library), you can only list the top 1000 apps of each category.
