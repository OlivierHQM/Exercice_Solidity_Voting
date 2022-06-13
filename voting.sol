// SPDX-License-Identifier: GPL - 3.0

pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable { 



    // Déclaration des event, de enum et des structures demandés dans l'énoncé de l'exercice    


    // Les events suivants informeront les utilisateurs de l'interface des étapes du processus de vote
    event VoterRegistred(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistred(uint proposalId);
    event Voted (address voter, uint proposalId);


    // enum WorkflowStatus est utilisé par l'administrateur pour gérer l'accessibilité aux fonctions de l'interface
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationsStarted,
        ProposalsRegistrationsEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }


    // struct Voter est une classe d'objet qui crée des objets enfants dotés de 3 propriétés
    // ces propriétés informent sur l'historique d'enregistrement et de vote d'un votant

    struct Voter {
        bool isRegistred;
        bool hasVoted;
        uint votedProposalId;
    }


    // struct Proposal est une classe d'objet qui crée des objets enfants dotés de 2 propriété
    // ces propriétés consigne des propostions de vote et leur score électoral 

    struct Proposal {
        string description;
        uint voteCount;
    }





    // Préparation d'une base de données qui stocke des adresses Eth de votants en les connectants à leur propriétés d'objet
    mapping (address=>Voter) voters;


    // Préparation d'un ensemble de structures qui stocke les propriétés des propositions en les classant dans l'ordre d'arrivée
    Proposal[] public proposals;


    // Préparation d'une base de données qui stocke des adresses Eth de votants en les connectant à l'index des propositions
    mapping (address=>uint) proposalsId;

    // Déclaration d'une variable qui stocke le dernier numéro d'Id des propositions déposées
    uint public proposalId;


    // Déclaration d'une variable d'index pour la fonction de comparaison
    uint i;

    // Déclaration d'une variable qui stocke le nombre maximal de voix pour une proposition
    uint maxVote;



    // Préparation d'un tableau qui récupère les propositions qui recoivent le même nombre de votes
    uint[] arrayForNewVote;

    // Déclaration de la variable qui récupère la proposition gagnante
    uint electedProposal;

    //***************************************************************
    // Suivi des phases du processus de vote


    // Declaration d'une variable qui recupère l'état de la phase du processus de vote
    // Intialiation de la variable avec la première phase du processus de vote    
    WorkflowStatus public defaultWorkflowStatus = WorkflowStatus.RegisteringVoters;



    // Création d'une fonction réservée à l'administrateur pour l'enregistrement des votants
    function registeringVoters (address _voterAddr) external onlyOwner {
        require(defaultWorkflowStatus == WorkflowStatus.RegisteringVoters, unicode"Vous n'êtes pas dans la phase de vote : enregistrement des votants");
        require (voters[ _voterAddr].isRegistred == false, unicode"Cette adresse est déjà enregistrée");
        voters[ _voterAddr] = Voter(true, false, 0);
        emit VoterRegistred( _voterAddr);
    }

    // Création d'une fonction pour ouvrir la phase d'enregistrement des propositions
    // Lettre "a" devant le nom de la fonction pour classer les fonctions dans l'ordre des phases dans l'interface remix
    function a_ProposalRegistrationStarted() external onlyOwner{
        require(defaultWorkflowStatus == WorkflowStatus.RegisteringVoters, unicode"Vous n'êtes pas dans la phase de vote : enregistrement des votants");
        defaultWorkflowStatus = WorkflowStatus.ProposalsRegistrationsStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationsStarted);
    }

    // Création d'une fonction pour enregistrer les propositions
    function proposalsRegistration(string calldata _description) external {
        require(defaultWorkflowStatus==WorkflowStatus.ProposalsRegistrationsStarted, unicode"Vous n'est pas dans la phase : enregistrement des propositions");
        require(voters[msg.sender].isRegistred=true, unicode"Cette adresse n'est pas autorisée à voter");
        Proposal memory proposal = Proposal( _description, 0);
        proposals.push(proposal);
        proposalId += 1;
        emit ProposalRegistred(proposalId);
    }

    // Création d'une fonction pour fermer la phase d'enregistrement des propositions
    function b_ProposalRegistrationEnded() external onlyOwner{
        require(defaultWorkflowStatus == WorkflowStatus.ProposalsRegistrationsStarted, unicode"Vous n'êtes pas dans la phase de vote : enregistrement des propositions");
        defaultWorkflowStatus = WorkflowStatus.ProposalsRegistrationsEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationsStarted, WorkflowStatus.ProposalsRegistrationsEnded);
    }    

    // Création d'une fonction pour ouvrir la phase de vote
    function c_VotingStarted() external onlyOwner{
        require(defaultWorkflowStatus == WorkflowStatus.ProposalsRegistrationsEnded, unicode"Vous n'êtes pas dans la phase de vote : fermeture de l'enregistrement des propositions");
        defaultWorkflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationsEnded, WorkflowStatus.VotingSessionStarted);
    }

    // Création d'une fonction pour enregistrer les votes
    function vote(uint _choice) external {
        require(defaultWorkflowStatus==WorkflowStatus.VotingSessionStarted, unicode"Vous n'êtes pas dans la phase de vote : enregistrement des votes");
        require(voters[msg.sender].isRegistred==true, unicode"Cette adresse n'est pas autorisée à voter");
        require(voters[msg.sender].hasVoted==false, unicode"Cette adresse a déjà voté");
        require( _choice <= proposalId, unicode"Cette proposition n'existe pas");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _choice;
        proposals[ _choice].voteCount +=1;
        emit Voted(msg.sender, _choice);
    }

    // Création d'une fonction pour fermer la phase de vote
    function d_VotingEnded() external onlyOwner{
        require(defaultWorkflowStatus==WorkflowStatus.VotingSessionStarted, unicode"Vous n'êtes pas dans la phase de vote : enregistrement des votes");
        defaultWorkflowStatus = WorkflowStatus.VotingSessionEnded; 
    }



    // Création d'une fonction pour comparer les propositions selon leur nombre de voix
    // Fonction utilisable uniquement par l'administrateur
    function compare() external onlyOwner {
        for (i=0; i <= proposals.length-1; i++) {
            if (proposals[i].voteCount > maxVote) {
                electedProposal = i;
                maxVote ++;
            } else if (proposals[i].voteCount == maxVote) {
                arrayForNewVote.push(i);
                
            
            }
        }
    }

    // Fonction qui retourne la proposition gagnante, s'il n'y a pas de score ex aequo

    function getWinner() external view returns(uint) {
        require(arrayForNewVote.length > 0, unicode"Il y a plusieurs propositions ex aequo, il faut organiser un vote de départage");
        return electedProposal;
    }





// Fin du contenu du contrat
} 