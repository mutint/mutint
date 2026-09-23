# MutInt

An integrated environment for predicting, curating, and learning from mutations in microbial genomes.

MutInt's [core](https://github.com/mutint/mutint-core) is a fork of [AleDB](https://github.com/Aletechdev/aledb).

_This project is in very early development! We recommend updating often to get bug fixes and new features._

## Installation

### System Requirements

We've run MutInt on a variety of machines, including older ones. The main thing you need is enough free hard drive space to install all of the necessary tools (~4 GB currently). 

However, depending on how you are importing data, you may need much more disk space than that to use MutInt for your projects. It may only take < 1 GB of additional space if you are analyzing existing mutation calls, but if you are running _breseq_ or other tools that keep intermediate files, including BAM alignment, you may need 50-100 GB or more free space, at least during the analysis phase. There are built-in ways to clear these files after you are done with them to manage MutInt's disk space usage (see #Management below).

### Easy Install

Download and run this installation script on MacOSX or Linux.

```bash
curl -LO https://raw.githubusercontent.com/mutint/mutint/main/install.sh
sh install.sh main
```

It should clone the MutInt GitHub repository and its components to your computer, install all needed components, and then start a local MutInt server that is only reachable by you in a web browser at the URL  

### Advanced Install

Clone the GitHub repository yourself.

```bash
git clone --recurse-submodules https://github.com/mutint/mutint.git
```

You must include the `--recurse-submodules` option! 

If you forget it, you can run this from the repo directory to make sure the submodules will be fetched and updated correctly.

```bash
git submodule update --init
```

## Starting MutInt

If you are on MacOSX, you should be able to double-click the App icon. It will perform the install steps described below and then open MutInt in your default web browser. If you are on Linux, you may be able to double-click the `Start MutInt.command` script to get the same initialization steps to run automatically.

If not, you can navigate to the repository directory and run this command on either platform:
```bash
./mutint start
```

On first run, MutInt will automatically:
1. Provision a pinned Python 3.13 and build a virtual environment (`env/main/`)
2. Install every component's `requirements.txt` into it
3. Install external tools components need using Conda (`env/tools/`)
4. Start PostgreSQL for database support.
5. Create a default admin user (`admin` / `admin`)
6. Open your default web browser to `http://127.0.0.1:8000`

Expect the first run to take several minutes while these components install. The next time you restart, it should be quicker.

Once you have MutInt showing in your web browser, you should log in as `admin` with password `admin`. Right now no version of MutInt allows connections from another computer, but you can change this default password (and create new users) if you wish.

## Updating MutInt

MutInt updates itself in place and is designed to keep your data intact across updates.

To update Mutint, sign in as a superuser (like the default `admin` user), click your username in the sidebar, then click **Update**. The update page that shows lists what plugin components are installed, and has a button to check for never newer versions of MutInt and all of its plugins.

Right now, while things are very new, we recommend choosing the "Development Releases" menu option for updates rather than the "Official Releases".

After you update there will be a button that quits MutInt so that the next time you launch it the updates are installed. If you started it from the MacOSX App, then it will automatically relaunch itself.

If you'd like to update from the terminal instead:
```bash
./mutint update --check    # (optional) Checks what is available
./mutint update            # Downloads the update
./mutint start             # Applies the update and starts MutInt
```

If things seem to get stuck or you encounter any weirdness, the best thing to do is to stop MutInt by quitting the app of the `./mutint start` process and start it again.

## Getting Started

In brief:
1. Create a Project.
2. Create an Experiment in this Project.
3. Add a Reference Genome to the Experiment.
4. Import mutation calls from GenomeDiff or VCF files OR run _breseq_ to predict mutations from FASTQ files.
5. Analyze and visualize your mutation calls to learn from them.

More to be added soon!

## Management

### Where is my data? How do I free up disk space?

The underlying database and all data files uploaded and used by MutInt are stored in the `data` directory within your MutInt install. If you need to free up memory, the safest way to do this is by clearing out data using the relevant buttons found in every Project and Experiment.

### Advanced

The `./mutint` script has other subcommands that can be used by expert users. Get the help at the command line.

In the future we plan to add options for configuring MutInt in more complex ways, including so it can be accessed over the web and use distributed workers on a cluster or in the cloud to carry out analysis tasks.
